import { getTopicByDate } from "../repositories/topicRepository.js";
import isCorrectGuess from "../utils/guessMatcher.js";

const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:3000";

const submitGame = async (
  topicId: string,
  attempts: number,
  guesses: string[],
  duration: number,
  success: boolean
) => {
  const response = await fetch(`${API_BASE_URL}/play/submit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ topicId, attempts, guesses, duration, success }),
  });
  if (!response.ok) {
    throw new Error("Failed to submit game");
  }
  const data = await response.json();
  console.log("Game submitted:", data);
};

const playExampleGame = async () => {
  const now = new Date();
  let date = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())); // UTC midnight for today's local date

  const dailyTopic = await getTopicByDate(date);
  const hints = dailyTopic?.hints.map((hint) => hint.content) || [];
  const guesses = [];

  console.log("Today's Topic:", dailyTopic?.answer);

  for (const [index, hint] of hints.entries()) {
    console.log(`Hint ${index + 1}: ${hint}`);
    console.log("Enter your guess:");

    const userInput = await new Promise<string>((resolve) => {
      const stdin = process.stdin;
      stdin.resume();
      stdin.once("data", (data) => {
        resolve(data.toString().trim());
      });
    });

    guesses.push(userInput);

    if (isCorrectGuess(dailyTopic!.answer, userInput)) {
      console.log("Correct! You've guessed the answer.");
      await submitGame(
        dailyTopic!.id,
        index + 1, // attempts
        guesses, // guesses
        (index + 1) * 15, // Example duration
        true // success
      );
      process.exit(0);
    } else {
      console.log("Incorrect guess. Loading next hint...\n");
    }
  }
  console.log("All hints used. The correct answer was:", dailyTopic?.answer);

  await submitGame(
    dailyTopic!.id,
    hints.length, // attempts
    guesses, // guesses
    hints.length * 15, // Example duration
    false // lost
  );
};

playExampleGame().then(() => {
  console.log("Game over! Better luck next time.");
  process.exit(0);
});
