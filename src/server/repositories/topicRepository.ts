import { prisma } from "../db/prisma.js";

/**
 * Gets the topic number for a given date (i.e., how many topics exist up to and including this date).
 * Used to display "Decipher #123" to users.
 */
export async function getTopicNumber(date: Date) {
  const count = await prisma.topic.count({
    where: {
      date: {
        lte: date,
      },
    },
  });
  return count;
}

/**
 * Fetches a topic by its date, including all hints ordered by hint order.
 */
export async function getTopicByDate(date: Date) {
  return prisma.topic.findUnique({
    where: { date },
    include: { hints: { orderBy: { order: "asc" } } },
  });
}

/**
 * Fetches all topics (answer, type, date only) ordered by most recent first.
 * Used by topic generation script to avoid duplicates.
 */
export async function getAllTopics() {
  return prisma.topic.findMany({
    select: { answer: true, type: true, date: true },
    orderBy: { date: "desc" },
  });
}

/**
 * Creates a new topic with its associated hints.
 */
export async function createTopic(data: {
  answer: string;
  date: Date;
  type: string;
  hints: { content: string; type: string; order: number }[];
}) {
  return prisma.topic.create({
    data: {
      answer: data.answer,
      date: data.date,
      type: data.type,
      hints: {
        create: data.hints,
      },
    },
    include: { hints: true },
  });
}
