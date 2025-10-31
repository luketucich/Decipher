import { distance } from "fastest-levenshtein";

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

function isCorrectGuess(answer: string, guess: string): boolean {
  const normAnswer = normalize(answer);
  const normGuess = normalize(guess);

  if (normAnswer === normGuess) {
    return true;
  }

  // Fuzzy match with Levenshtein
  const maxLength = Math.max(normAnswer.length, normGuess.length);
  const dist = distance(normAnswer, normGuess);
  const threshold = Math.ceil(maxLength * 0.45);

  return dist <= threshold;
}

export default isCorrectGuess;
