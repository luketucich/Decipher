/// <reference lib="deno.ns" />

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type TopicStatsRequest = {
  topicId?: unknown;
};

type SubmissionRow = {
  guesses: string[] | null;
  duration: number;
  attempts: number;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function emptyStats() {
  return {
    totalSubmissions: 0,
    avgGuessTime: 0,
    fastestGuessTime: 0,
    avgSkips: 0,
    skipRate: 0,
    commonGuesses: [] as Array<{ guess: string; count: number }>,
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

    const payload = (await req.json()) as TopicStatsRequest;
    const topicId = typeof payload.topicId === "string" ? payload.topicId.trim() : "";

    if (!topicId) {
      return jsonResponse({ error: "Topic ID is required." }, 400);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const attempts: Array<{
      table: "Submission" | "submission";
      topicIdColumn: "topicId" | "topicid";
    }> = [
      { table: "Submission", topicIdColumn: "topicId" },
      { table: "submission", topicIdColumn: "topicid" },
    ];

    let submissions: SubmissionRow[] = [];
    let resolved = false;
    let lastError: unknown = null;

    for (const attempt of attempts) {
      const { data, error } = await supabase
        .from(attempt.table)
        .select("guesses,duration,attempts")
        .eq(attempt.topicIdColumn, topicId);

      if (error) {
        lastError = error;
        continue;
      }

      submissions = (data ?? []) as SubmissionRow[];
      resolved = true;
      break;
    }

    if (!resolved) {
      console.error("topic-stats query error", lastError);
      return jsonResponse({ error: "Failed to fetch stats." }, 500);
    }

    if (submissions.length === 0) {
      return jsonResponse(emptyStats());
    }

    const frequency = new Map<string, number>();
    let totalSkips = 0;
    let totalHintSlotsUsed = 0;
    for (const submission of submissions) {
      const guessCount = submission.guesses?.length ?? 0;
      const attemptCount = Number.isInteger(submission.attempts)
        ? submission.attempts
        : guessCount;
      const inferredSkips = Math.max(0, Math.min(5, attemptCount - guessCount));
      totalSkips += inferredSkips;
      totalHintSlotsUsed += Math.max(0, Math.min(5, attemptCount));

      for (const guess of submission.guesses ?? []) {
        const normalized = guess.toLowerCase().trim();
        if (!normalized) {
          continue;
        }
        frequency.set(normalized, (frequency.get(normalized) ?? 0) + 1);
      }
    }

    const commonGuesses = Array.from(frequency.entries())
      .map(([guess, count]) => ({ guess, count }))
      .sort((a, b) => b.count - a.count || a.guess.localeCompare(b.guess));

    const durations = submissions.map((entry) => entry.duration);
    const avgGuessTime = Math.round(
      durations.reduce((acc, value) => acc + value, 0) / durations.length,
    );
    const fastestGuessTime = Math.min(...durations);
    const avgSkips = Number((totalSkips / submissions.length).toFixed(2));
    const skipRate = totalHintSlotsUsed > 0
      ? Number((totalSkips / totalHintSlotsUsed).toFixed(4))
      : 0;

    return jsonResponse({
      totalSubmissions: submissions.length,
      avgGuessTime,
      fastestGuessTime,
      avgSkips,
      skipRate,
      commonGuesses,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid request";
    return jsonResponse({ error: message }, 400);
  }
});
