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
