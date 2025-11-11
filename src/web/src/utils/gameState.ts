import type { GameProgress } from '../types';

const STORAGE_KEY = 'decipher_game_progress';

export function saveGameProgress(progress: GameProgress): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
}

export function loadGameProgress(): GameProgress | null {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) return null;
  
  try {
    const progress: GameProgress = JSON.parse(stored);
    // Check if progress is from today
    const today = new Date().toISOString().split('T')[0];
    if (progress.date !== today) {
      clearGameProgress();
      return null;
    }
    return progress;
  } catch {
    return null;
  }
}

export function clearGameProgress(): void {
  localStorage.removeItem(STORAGE_KEY);
}

export function hasPlayedToday(): boolean {
  const progress = loadGameProgress();
  return progress?.completed === true;
}
