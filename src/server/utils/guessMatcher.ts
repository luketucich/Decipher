import { distance } from "fastest-levenshtein";

/**
 * Normalizes a string for comparison by:
 * - Converting to lowercase
 * - Removing articles (the, a, an)
 * - Removing punctuation and symbols
 * - Collapsing multiple spaces
 */
function normalize(str: string): string {
  str = str.toLowerCase();
  // Remove articles, punctuation/symbols, extra spaces
  str = str
    .replace(/\b(the|a|an)\b/g, " ")
    .replace(/[^a-z0-9\s]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  return str;
}

/**
 * Checks if a guess is correct by comparing it to the answer.
 * Uses exact match after normalization, then falls back to fuzzy matching.
 * Fuzzy matching allows up to 45% character differences (Levenshtein distance).
 * This threshold balances accepting typos while rejecting clearly wrong answers.
 */
function isCorrectGuess(answer: string, guess: string): boolean {
  const normAnswer = normalize(answer);
  const normGuess = normalize(guess);

  if (normAnswer === normGuess) {
    return true;
  }

  // Fuzzy match with Levenshtein distance
  // Allow up to 45% character differences based on the longer string
  const maxLength = Math.max(normAnswer.length, normGuess.length);
  const dist = distance(normAnswer, normGuess);
  const threshold = Math.ceil(maxLength * 0.45);

  return dist <= threshold;
}

export default isCorrectGuess;
