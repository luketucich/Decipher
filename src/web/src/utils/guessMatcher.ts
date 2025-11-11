import { distance } from 'fastest-levenshtein';

export function normalize(str: string): string {
  let s = str.toLowerCase();
  // Remove articles
  s = s.replace(/\b(the|a|an)\b/g, ' ');
  // Remove punctuation/symbols
  s = s.replace(/[^a-z0-9\s]/g, '');
  // Collapse whitespace
  s = s.replace(/\s+/g, ' ');
  return s.trim();
}

export function isCorrectGuess(answer: string, guess: string): boolean {
  const normAnswer = normalize(answer);
  const normGuess = normalize(guess);

  if (normAnswer === normGuess) return true;

  const maxLength = Math.max(normAnswer.length, normGuess.length);
  const dist = distance(normAnswer, normGuess);
  const threshold = Math.ceil(maxLength * 0.45);
  
  return dist <= threshold;
}
