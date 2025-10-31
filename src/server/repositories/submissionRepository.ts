import { prisma } from "../db/prisma.js";

/**
 * Saves a game submission (both wins and losses) to the database.
 */
export async function createSubmission(data: {
  topicId: string;
  attempts: number;
  guesses: string[];
  duration: number;
  success: boolean;
}) {
  return prisma.submission.create({
    data,
  });
}

/**
 * Gets aggregated stats for a specific topic.
 * Returns most common guesses, average/fastest guess times, and total submissions.
 */
export async function getTopicStats(topicId: string) {
  // Get all submissions for this topic
  const submissions = await prisma.submission.findMany({
    where: { topicId },
    select: {
      guesses: true,
      duration: true,
    },
  });

  if (submissions.length === 0) {
    return {
      totalSubmissions: 0,
      avgGuessTime: 0,
      fastestGuessTime: 0,
      commonGuesses: [],
    };
  }

  // Calculate guess frequency
  const guessFrequency = new Map<string, number>();
  submissions.forEach((submission) => {
    submission.guesses.forEach((guess) => {
      const normalized = guess.toLowerCase().trim();
      if (normalized) {
        guessFrequency.set(
          normalized,
          (guessFrequency.get(normalized) || 0) + 1
        );
      }
    });
  });

  // Sort by frequency and take top 20
  const commonGuesses = Array.from(guessFrequency.entries())
    .map(([guess, count]) => ({ guess, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 20);

  // Calculate time stats
  const durations = submissions.map((s) => s.duration);
  const avgGuessTime = Math.round(
    durations.reduce((sum, d) => sum + d, 0) / durations.length
  );
  const fastestGuessTime = Math.min(...durations);

  return {
    totalSubmissions: submissions.length,
    avgGuessTime,
    fastestGuessTime,
    commonGuesses,
  };
}
