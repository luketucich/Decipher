import { prisma } from "../db/prisma.js";

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

export async function getTopicByDate(date: Date) {
  return prisma.topic.findUnique({
    where: { date },
    include: { hints: { orderBy: { order: "asc" } } },
  });
}

export async function getAllTopics() {
  return prisma.topic.findMany({
    select: { answer: true, type: true, date: true },
    orderBy: { date: "desc" },
  });
}

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
