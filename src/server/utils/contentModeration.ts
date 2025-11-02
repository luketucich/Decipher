import OpenAI from "openai";
import leo from "leo-profanity";

// Initialize OpenAI client for moderation (uses standard OpenAI, not X.AI)
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export interface ModerationResult {
  flagged: boolean;
  categories?: {
    hate: boolean;
    "hate/threatening": boolean;
    harassment: boolean;
    "harassment/threatening": boolean;
    "self-harm": boolean;
    "self-harm/intent": boolean;
    "self-harm/instructions": boolean;
    sexual: boolean;
    "sexual/minors": boolean;
    violence: boolean;
    "violence/graphic": boolean;
  };
  reason?: string;
}

/**
 * Check if content is appropriate using OpenAI Moderation API
 * @param text - The text to check for inappropriate content
 * @returns ModerationResult with flagged status and details
 */
/**
 * Check if text contains only allowed characters
 * Allows: a-z, A-Z, 0-9, spaces, and basic punctuation
 */
function hasValidCharacters(text: string): boolean {
  // Allow letters, numbers, spaces, and common punctuation: . , ! ? ' " - : ; ( ) & /
  const allowedPattern = /^[a-zA-Z0-9\s.,!?'"\-:;()&\/]+$/;
  return allowedPattern.test(text);
}

export async function moderateContent(
  text: string
): Promise<ModerationResult> {
  try {
    // Basic validation
    if (!text || text.trim().length === 0) {
      return { flagged: false };
    }

    // Layer 1: Character validation
    if (!hasValidCharacters(text)) {
      return {
        flagged: true,
        reason: "Please use only letters, numbers, and basic punctuation",
      };
    }

    // Layer 2: Profanity check
    if (leo.check(text)) {
      return {
        flagged: true,
        reason: "Please keep your guesses appropriate and avoid profanity",
      };
    }

    // Layer 3: OpenAI Moderation API for harmful content
    // (violence, self-harm, hate speech, etc.)
    const moderation = await openai.moderations.create({
      input: text,
    });

    const result = moderation.results[0];

    if (!result) {
      return { flagged: false };
    }

    if (result.flagged) {
      // Find which categories were flagged
      const flaggedCategories = Object.entries(result.categories)
        .filter(([_, value]) => value)
        .map(([key]) => key);

      return {
        flagged: true,
        categories: result.categories,
        reason: `Content flagged for: ${flaggedCategories.join(", ")}`,
      };
    }

    return { flagged: false };
  } catch (error) {
    console.error("Error moderating content:", error);
    // If moderation API fails, allow the content but log the error
    // You can make this stricter by returning { flagged: true } on error
    return { flagged: false };
  }
}
