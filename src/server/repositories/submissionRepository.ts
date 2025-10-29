import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

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
