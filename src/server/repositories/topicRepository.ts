import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export async function getTopicByDate(date: Date) {
  return prisma.topic.findUnique({
    where: { date },
    include: { hints: { orderBy: { id: "asc" } } },
  });
}
