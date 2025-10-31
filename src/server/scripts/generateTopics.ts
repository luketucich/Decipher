import dotenv from "dotenv";
import OpenAI from "openai";
import { getAllTopics } from "../repositories/topicRepository.js";

dotenv.config();

const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:3000";
const ADMIN_TOKEN = process.env.ADMIN_TOKEN;

const openai = new OpenAI({
  apiKey: process.env.XAI_API_KEY,
  baseURL: "https://api.x.ai/v1",
});

async function generateTopic(
  date: string,
  pastTopics: { answer: string; type: string }[]
) {
  const pastAnswers = pastTopics.map((t) => t.answer).join(", "); // Clean list of answers only

  const prompt = `
    Generate a daily puzzle topic for my guessing game Decipher.
    The goal is to guess the daily topic based on a series of hints.

    There are seven topics per week, one for each day (Monday to Sunday).
    Monday: Movie
    Tuesday: Book
    Wednesday: History (Person or Event)
    Thursday: Music (Song or Album)
    Friday: TV Show
    Saturday: Public Figure (Celebrity, Politician, etc.)
    Sunday: Miscellaneous (can be anything fun and interesting)

    **Today is ${date}. Only use holiday-themed topics if today is EXACTLY a major holiday (e.g., spooky for Halloween on October 31; festive for Christmas on December 25). Do NOT theme for nearby dates.**

    **Furthermore, you MUST NOT use any of the following past answers (or very similar ones) that have already been used: ${
      pastAnswers || "None"
    }. Generate something completely new and unique.**

    The hints should start vague and get more specific. **Make hints challenging: the first 2-3 should be subtle, requiring thought; avoid obvious giveaways early.**

    The first hint should be a Category (like "1920s Action Movie" or "Famous Scientist")
    The second hint should be an Emoji representation (please use only emojis, no text)
    The third hint should be a Quote related to the answer.
    The fourth hint should be a Trivia fact.
    The fifth hint should be a Definition or direct clue.

    For daily topics, focus on well-known subjects from various categories like Movies, Books, Historical Figures, Songs, etc.
    Feel free to do pop culture references, but avoid overly obscure topics. **Choose topics that are recognizable but not too easy, aim for medium-hard difficulty where players might need 3-4 hints.**

    Try to make the game challenging and fun!

    Output ONLY valid JSON: {
      "answer": "string (the secret word/phrase)",
      "type": "string (e.g., Movie, Book, Public Figure)",
      "hints": [
        {"content": "string", "type": "string", "order": 1},
        {"content": "string", "type": "string", "order": 2},
        ... (exactly 5 hints)
      ]
    }

    In the JSON the "type" field for the topic needs to exactly match one of the following: Movie, Book, Historical Event, Historical Figure, Song, Album, Music, TV Show, Public Figure, Miscellaneous.
    In the JSON the "type" field for each hint needs to exactly match one of the following: Category, Emoji, Quote, Trivia, Definition.
  `;

  const response = await openai.chat.completions.create({
    model: "grok-4",
    messages: [{ role: "user", content: prompt }],
    temperature: 1.0,
    max_tokens: 500,
  });

  const generatedText = response.choices[0]?.message?.content || "";
  let generated;
  try {
    generated = JSON.parse(generatedText);
  } catch (e) {
    throw new Error("Invalid JSON from Grok");
  }

  generated.date = date;

  const postResponse = await fetch(`${API_BASE_URL}/admin/topic`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-admin-token": ADMIN_TOKEN ?? "",
    },
    body: JSON.stringify(generated),
  });

  if (!postResponse.ok) {
    throw new Error("Failed to create topic");
  }

  console.log("Topic created:", await postResponse.json());
}

const generateTopics = async (amount: number) => {
  console.log(`Generating ${amount} topics...`);
  for (let i = 0; i < amount; i++) {
    // Fetch past topics each iteration to get the latest, which ensures no duplicates
    const pastTopics = await getAllTopics();

    // Get next date to generate topic for
    let date: Date;
    if (pastTopics.length > 0 && pastTopics[0]?.date) {
      const lastDate = new Date(pastTopics[0].date);
      date = new Date(
        Date.UTC(
          lastDate.getUTCFullYear(),
          lastDate.getUTCMonth(),
          lastDate.getUTCDate() + 1
        )
      ); // add one day at UTC
    } else {
      const now = new Date();
      date = new Date(
        Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())
      ); // UTC midnight for today's local date
    }

    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, "0");
    const day = String(date.getUTCDate()).padStart(2, "0");
    const dateStr = `${year}-${month}-${day}`; // YYYY-MM-DD

    try {
      await generateTopic(dateStr, pastTopics);
    } catch (error) {
      console.error(`Error generating topic for ${dateStr}:`, error);
    }
  }
};

generateTopics(7).then(() => {
  console.log("Topic generation complete");
  process.exit(0);
});
