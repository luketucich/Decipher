/// <reference lib="deno.ns" />

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type SubmitGameRequest = {
  topicId?: unknown;
  attempts?: unknown;
  guesses?: unknown;
  skips?: unknown;
  duration?: unknown;
  success?: unknown;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function parseRequest(payload: SubmitGameRequest) {
  const topicId =
    typeof payload.topicId === "string" ? payload.topicId.trim() : "";
  const attempts = payload.attempts;
  const guesses = payload.guesses;
  const skips = payload.skips;
  const duration = payload.duration;
  const success = payload.success;

  if (!topicId) {
    throw new Error("Topic ID is required.");
  }

  if (typeof attempts !== "number" || !Number.isInteger(attempts) || attempts < 1 || attempts > 5) {
    throw new Error("Attempts must be an integer between 1 and 5.");
  }

  if (!Array.isArray(guesses) || guesses.length > 5) {
    throw new Error("Guesses must be an array with up to 5 entries.");
  }

  const cleanedGuesses = guesses.map((guess) => {
    if (typeof guess !== "string") {
      throw new Error("Each guess must be a string.");
    }
    const cleaned = guess.trim();
    if (!cleaned) {
      throw new Error("Guesses cannot be empty.");
    }
    if (cleaned.length > 120) {
      throw new Error("Guesses must be 120 characters or fewer.");
    }
    return cleaned;
  });

  let parsedSkips = attempts - cleanedGuesses.length;
  if (skips !== undefined) {
    if (typeof skips !== "number" || !Number.isInteger(skips) || skips < 0 || skips > 5) {
      throw new Error("Skips must be an integer between 0 and 5.");
    }
    parsedSkips = skips;
  }

  if (!Number.isInteger(parsedSkips) || parsedSkips < 0 || parsedSkips > 5) {
    throw new Error("Skips must be an integer between 0 and 5.");
  }

  if (cleanedGuesses.length + parsedSkips !== attempts) {
    throw new Error("Attempts must equal guesses plus skips.");
  }

  if (success === true && cleanedGuesses.length === 0) {
    throw new Error("A successful game requires at least one guess.");
  }

  if (typeof duration !== "number" || !Number.isInteger(duration) || duration < 0) {
    throw new Error("Duration must be a non-negative integer.");
  }

  if (typeof success !== "boolean") {
    throw new Error("Success must be a boolean.");
  }

  return {
    id: crypto.randomUUID(),
    topicId,
    attempts,
    guesses: cleanedGuesses,
    skips: parsedSkips,
    duration,
    success,
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

    const payload = (await req.json()) as SubmitGameRequest;
    const parsed = parseRequest(payload);

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const camelInsert = {
      id: parsed.id,
      topicId: parsed.topicId,
      attempts: parsed.attempts,
      guesses: parsed.guesses,
      duration: parsed.duration,
      success: parsed.success,
    };

    const lowerInsert = {
      id: parsed.id,
      topicid: parsed.topicId,
      attempts: parsed.attempts,
      guesses: parsed.guesses,
      duration: parsed.duration,
      success: parsed.success,
    };

    const attempts = [
      {
        table: "Submission",
        payload: camelInsert,
        select: "id,topicId,attempts,guesses,duration,success,createdAt",
      },
      {
        table: "submission",
        payload: lowerInsert,
        select: "id,topicid,attempts,guesses,duration,success,createdat",
      },
    ] as const;

    let saved: Record<string, unknown> | null = null;
    let lastError: unknown = null;

    for (const attempt of attempts) {
      const { data, error } = await supabase
        .from(attempt.table)
        .insert(attempt.payload)
        .select(attempt.select)
        .single();

      if (error) {
        lastError = error;
        continue;
      }

      saved = (data ?? null) as Record<string, unknown> | null;
      break;
    }

    if (!saved) {
      const pgError = lastError as { code?: string } | null;
      console.error("submit-game insert error", lastError);
      if (pgError?.code === "23503") {
        return jsonResponse({ error: "Topic ID does not exist." }, 400);
      }
      return jsonResponse({ error: "Failed to submit game." }, 500);
    }

    const normalizedResponse = {
      id: String(saved.id ?? ""),
      topicId: String(saved.topicId ?? saved.topicid ?? ""),
      attempts: Number(saved.attempts ?? 0),
      guesses: Array.isArray(saved.guesses) ? saved.guesses : [],
      skips: parsed.skips,
      duration: Number(saved.duration ?? 0),
      success: Boolean(saved.success),
      createdAt: String(saved.createdAt ?? saved.createdat ?? ""),
    };

    return jsonResponse(normalizedResponse, 201);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid request";
    return jsonResponse({ error: message }, 400);
  }
});
