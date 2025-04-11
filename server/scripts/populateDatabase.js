const {
  isInDatabase,
  getLastTopic,
  createTopic,
} = require("../controllers/prismaQueries");

const {
  getKeywordVariations,
  getHints,
} = require("../controllers/wikiFetcher");

const path = require("path");
const fs = require("fs/promises");

// Helper function to remove a topic from articles.txt
const handleRemoveTopic = async (topic, filePath) => {
  try {
    // Read the current file content
    const currentFileContent = await fs.readFile(filePath, "utf8");

    // Split into lines and filter out the topic to remove
    const articles = currentFileContent
      .split("\n")
      .filter((line) => line.trim() !== "" && line.trim() !== topic);

    // Write the updated content back to the file
    await fs.writeFile(filePath, articles.join("\n"));

    console.log(`Removed topic "${topic}" from articles list`);
    return true;
  } catch (error) {
    console.error(`Error removing topic "${topic}":`, error);
    return false;
  }
};

// Helper function to return topic as object with variations and hints
const getTopic = async (topic, articlesFilePath) => {
  try {
    let topicObject = {
      keyword: topic,
      variations: getKeywordVariations(topic),
      hints: (await getHints(topic)).slice(0, 5).reverse(),
    };

    if (topicObject.hints.length < 5) {
      const removed = await handleRemoveTopic(topic, articlesFilePath);
      if (removed) {
        console.log(
          `Topic "${topic}" has insufficient hints, removed from list`
        );
      }
      return null;
    }

    return topicObject;
  } catch (error) {
    console.error(`Error processing topic "${topic}":`, error);
    await handleRemoveTopic(topic, articlesFilePath);
    return null;
  }
};

function shuffle(array) {
  let currentIndex = array.length;

  // While there remain elements to shuffle
  while (currentIndex != 0) {
    // Pick a remaining element
    let randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    // And swap it with the current element.
    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex],
      array[currentIndex],
    ];
  }
}

async function main() {
  // Open the articles.txt file and extract the topics
  const articlesFilePath = path.join(__dirname, "..", "topics.txt");
  const fileContent = await fs.readFile(articlesFilePath, "utf8");
  const articles = fileContent
    .split("\n")
    .filter((line) => line.trim() !== "" && line.charAt(0) !== "#");

  shuffle(articles);

  // Declare the release date of the first topic to be added
  let initialReleaseDate = new Date("2025-04-12T00:00:00-05:00"); // 12 AM EST on April 12, 2025

  const lastTopic = await getLastTopic(); // If last topic exists, use its release date
  if (lastTopic !== null) {
    const nextDay = new Date(lastTopic.releaseDate);
    nextDay.setDate(nextDay.getDate() + 1);
    initialReleaseDate = nextDay;
  }

  if (lastTopic) {
    console.log("Last topic:", lastTopic);
  } else {
    console.log("No last topic found. Starting with date:", initialReleaseDate);
  }

  // Process each article sequentially
  for (const article of articles) {
    const isAlreadyInDb = await isInDatabase(article);

    if (!isAlreadyInDb) {
      const topicObject = await getTopic(article, articlesFilePath);

      if (topicObject) {
        const releaseDate = new Date(initialReleaseDate);

        try {
          // Add the topic to the database
          const topic = await createTopic(
            topicObject.keyword,
            topicObject.variations,
            topicObject.hints,
            releaseDate
          );

          console.log(
            `Added topic "${topic.keyword}" to the database with release date ${releaseDate}`
          );

          // Increment the initial release date for the next topic
          initialReleaseDate.setDate(initialReleaseDate.getDate() + 1);
        } catch (error) {
          console.error(`Error adding topic "${article}" to database:`, error);
          await handleRemoveTopic(article, articlesFilePath);
        }
      } else {
        console.log(`Failed to add topic "${article}"`);
      }
    } else {
      console.log(
        `Topic "${article}" already exists in the database, skipping`
      );
    }
  }

  console.log("All topics processed.");
}

main().catch((error) => {
  console.error("Error in main process:", error);
  process.exit(1);
});
