const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

const isInDatabase = async (keyword) => {
  try {
    const topic = await prisma.topic.findUnique({
      where: {
        keyword,
      },
    });
    return topic !== null;
  } catch (error) {
    console.error("Error checking topic existence:", error);
    throw error;
  }
};

const getLastTopic = async () => {
  try {
    // Check if table has at least one entry
    const count = await prisma.topic.count();
    if (count === 0) {
      return null;
    }

    const topic = await prisma.topic.findFirst({
      orderBy: {
        id: "desc",
      },
    });
    return topic;
  } catch (error) {
    console.error("Error fetching last topic:", error);
    throw error;
  }
};

const createTopic = async (keyword, variations, hints, releaseDate) => {
  try {
    const topic = await prisma.topic.create({
      data: {
        keyword,
        variations,
        hints,
        releaseDate,
      },
    });
    return topic;
  } catch (error) {
    console.error("Error creating topic:", error);
    throw error;
  }
};

module.exports = {
  isInDatabase,
  getLastTopic,
  createTopic,
};
