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

    **Furthermore, you MUST NOT use any of the following past answers (or very similar ones, including synonyms, sequels, or related entries) that have already been used: ${
      pastAnswers || "None"
    }. Generate something completely new, unique, and less predictable.**

    The hints should start vague and get more specific. **Make hints challenging: the first 2-3 should be subtle, requiring thought; avoid obvious giveaways early.** **Ensure the first 3 hints are highly abstract and indirect, forcing players to connect multiple dots; only the last 2 should provide clearer ties to the answer.** **Design hints so they build cumulatively; each subsequent hint should only make sense in combination with previous ones, avoiding standalone reveals.**

    The first hint should be a Broad Category (like 'Early 20th Century Adventure Film' or 'Influential Theoretical Physicist') that avoids key identifiers.
    The second hint should be an Emoji representation (please use only emojis, no text). Use 3-5 emojis that symbolically represent themes or elements indirectly, without direct icons of the answer.
    The third hint should be an Obscure Quote related to the answer, perhaps from a secondary source or lesser-known context.
    The fourth hint should be a Trivia fact.
    The fifth hint should be a Definition or direct clue.

    For daily topics, focus on well-known subjects from various categories like Movies, Books, Historical Figures, Songs, etc.
    Feel free to do pop culture references, but avoid overly obscure topics. **Choose topics that are recognizable but lean toward medium-hard to hard difficulty, where players typically need 4-5 hints; prioritize subjects with niche cultural significance or lesser-known details over mainstream hits.**

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

// Parse command-line argument for the number of topics (default to 1 if not provided)
const args = process.argv.slice(2);
const amount = args.length > 0 ? parseInt(args[0]!, 10) : 1;
if (isNaN(amount) || amount <= 0) {
  console.error(
    "Please provide a valid positive number for the amount of topics."
  );
  process.exit(1);
}

generateTopics(amount).then(() => {
  console.log("Topic generation complete");
  process.exit(0);
});
