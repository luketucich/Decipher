import type { GameStats, ModerationResponse, Topic } from "../types";

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:3000";

export const api = {
  async fetchDailyTopic(): Promise<Topic> {
    const today = new Date();
    const dateStr = today.toISOString().split("T")[0]; // YYYY-MM-DD

    const response = await fetch(`${API_BASE_URL}/play/daily?date=${dateStr}`);
    if (!response.ok) {
      throw new Error("Failed to fetch daily topic");
    }
    return response.json();
  },

  async submitGame(data: {
    topicId: string;
    attempts: number;
    guesses: string[];
    duration: number;
    success: boolean;
  }): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/play/submit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("Failed to submit game");
    }
  },

  async getStats(topicId: string): Promise<GameStats> {
    const response = await fetch(`${API_BASE_URL}/play/stats/${topicId}`);
    if (!response.ok) {
      throw new Error("Failed to fetch stats");
    }
    return response.json();
  },

  async moderateGuess(guess: string): Promise<ModerationResponse> {
    const response = await fetch(`${API_BASE_URL}/play/moderate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ guess }),
    });

    if (!response.ok) {
      throw new Error("Failed to moderate guess");
    }
    return response.json();
  },
};
