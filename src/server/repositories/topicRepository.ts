import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export async function getTopicByDate(date: Date) {
  return prisma.topic.findUnique({
    where: { date },
    include: { hints: { orderBy: { id: "asc" } } },
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
