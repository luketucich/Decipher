/// <reference lib="deno.ns" />

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

type DailyTopicRequest = {
  date?: string;
};

type TopicRow = {
  id: string;
  answer: string;
  date: string;
  type: string;
  aliases?: string[] | null;
};

type HintRow = {
  id: string;
  content: string;
  type: string;
  order: number;
};

type TopicQueryResult = {
  topic: TopicRow | null;
  table: "Topic" | "topic";
  includesAliases: boolean;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function summarizeError(error: unknown): string {
  if (!error) {
    return "Unknown error";
  }

  if (typeof error === "string") {
    return error;
  }

  if (typeof error === "object") {
    const maybeRecord = error as Record<string, unknown>;
    const parts: string[] = [];
    if (typeof maybeRecord.message === "string") {
      parts.push(maybeRecord.message);
    }
    if (typeof maybeRecord.code === "string") {
      parts.push(`code=${maybeRecord.code}`);
    }
    if (typeof maybeRecord.details === "string" && maybeRecord.details.length > 0) {
      parts.push(`details=${maybeRecord.details}`);
    }
    if (typeof maybeRecord.hint === "string" && maybeRecord.hint.length > 0) {
      parts.push(`hint=${maybeRecord.hint}`);
    }
    if (parts.length > 0) {
      return parts.join(" | ");
    }
  }

  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

function parseDateString(dateText: string): Date {
  if (!DATE_REGEX.test(dateText)) {
    throw new Error("Date must be in YYYY-MM-DD format.");
  }

  const [yearText, monthText, dayText] = dateText.split("-");
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);

  const parsed = new Date(Date.UTC(year, month - 1, day));
  if (Number.isNaN(parsed.getTime())) {
    throw new Error("Invalid date provided.");
  }

  return parsed;
}

function getDateBoundsUTC(requestedDate?: string): {
  startIso: string;
  endIso: string;
} {
  const dayStart = requestedDate
    ? parseDateString(requestedDate)
    : (() => {
        const now = new Date();
        return new Date(
          Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
        );
      })();

  const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);

  return {
    startIso: dayStart.toISOString(),
    endIso: dayEnd.toISOString(),
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");

    if (!serviceRoleKey || !supabaseUrl) {
      return jsonResponse({ error: "Server misconfigured" }, 500);
    }

    if (serviceRoleKey.startsWith("sb_publishable_")) {
      return jsonResponse({
        error: "Server misconfigured",
        details: "SUPABASE_SERVICE_ROLE_KEY is set to a publishable key. Use the service role secret key."
      }, 500);
    }

    let payload: DailyTopicRequest = {};
    try {
      const parsed = (await req.json()) as DailyTopicRequest;
      payload = parsed ?? {};
    } catch {
      payload = {};
    }

    const { startIso, endIso } = getDateBoundsUTC(payload.date);

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const topicAttempts: Array<{
      table: "Topic" | "topic";
      select: string;
      includesAliases: boolean;
    }> = [
      { table: "Topic", select: "id,answer,date,type,aliases", includesAliases: true },
      { table: "Topic", select: "id,answer,date,type", includesAliases: false },
      { table: "topic", select: "id,answer,date,type,aliases", includesAliases: true },
      { table: "topic", select: "id,answer,date,type", includesAliases: false },
    ];
    let topicLookup: TopicQueryResult | null = null;
    const topicLookupErrors: string[] = [];

    for (const attempt of topicAttempts) {
      const { data, error } = await supabase
        .from(attempt.table)
        .select(attempt.select)
        .gte("date", startIso)
        .lt("date", endIso)
        .order("date", { ascending: true })
        .limit(1);

      if (error) {
        topicLookupErrors.push(
          `${attempt.table} (${attempt.select}): ${summarizeError(error)}`,
        );
        continue;
      }

      topicLookup = {
        topic: ((Array.isArray(data) ? data[0] : null) as TopicRow | null) ?? null,
        table: attempt.table,
        includesAliases: attempt.includesAliases,
      };
      break;
    }

    if (!topicLookup) {
      console.error("daily-topic topic query error", topicLookupErrors);
      return jsonResponse(
        {
          error: "Failed to fetch topic",
          details: topicLookupErrors.join(" || "),
        },
        500,
      );
    }

    const topic = topicLookup.topic;
    const topicTable = topicLookup.table;
    const includesAliases = topicLookup.includesAliases;

    if (!topic) {
      return jsonResponse({ error: "No topic found for today" }, 404);
    }

    const hintAttempts: Array<{
      table: "Hint" | "hint";
      topicIdColumn: "topicId" | "topicid";
    }> = [
      { table: "Hint", topicIdColumn: "topicId" },
      { table: "hint", topicIdColumn: "topicid" },
    ];
    let hints: HintRow[] = [];
    let hintsResolved = false;
    let hintsError: unknown = null;

    for (const attempt of hintAttempts) {
      const { data, error } = await supabase
        .from(attempt.table)
        .select("id,content,type,order")
        .eq(attempt.topicIdColumn, topic.id)
        .order("order", { ascending: true });

      if (error) {
        hintsError = error;
        continue;
      }

      hints = (data ?? []) as HintRow[];
      hintsResolved = true;
      break;
    }

    if (!hintsResolved) {
      console.error("daily-topic hint query error", hintsError);
      return jsonResponse(
        {
          error: "Failed to fetch hints",
          details: summarizeError(hintsError),
        },
        500,
      );
    }

    const countAttempts: Array<"Topic" | "topic"> = [topicTable, topicTable === "Topic" ? "topic" : "Topic"];
    let topicNumber = 0;
    let countResolved = false;
    let countError: unknown = null;

    for (const tableName of countAttempts) {
      const { count, error } = await supabase
        .from(tableName)
        .select("id", { count: "exact", head: true })
        .lte("date", topic.date);

      if (error) {
        countError = error;
        continue;
      }

      topicNumber = count ?? 0;
      countResolved = true;
      break;
    }

    if (!countResolved) {
      console.error("daily-topic count query error", countError);
      return jsonResponse(
        {
          error: "Failed to compute topic number",
          details: summarizeError(countError),
        },
        500,
      );
    }

    return jsonResponse({
      id: topic.id,
      answer: topic.answer,
      date: topic.date,
      type: topic.type,
      aliases: includesAliases ? (topic.aliases ?? []) : [],
      hints,
      topicNumber,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    console.error("daily-topic function error", message);
    return jsonResponse({ error: message }, 400);
  }
});
