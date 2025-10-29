import { type Request, type Response } from "express";
import { createSubmission } from "../repositories/submissionRepository.js";
import { getTopicByDate } from "../repositories/topicRepository.js";

export const getDaily = async (req: Request, res: Response) => {
  try {
    const today = new Date().toISOString().split("T")[0]!; // Get YYYY-MM-DD format
    const topic = await getTopicByDate(new Date(today));

    if (!topic) {
      return res.status(404).json({ message: "No topic found for today." });
    }

    return res.status(200).json(topic);
  } catch (error) {
    console.error("Error fetching daily topic:", error);
    return res.status(500).json({ message: "Internal server error." });
  }
};

export const submitGame = async (req: Request, res: Response) => {
  const { topicId, attempts, guesses, duration, success } = req.body;

  if (
    !topicId ||
    typeof attempts !== "number" ||
    !Array.isArray(guesses) ||
    typeof duration !== "number" ||
    typeof success !== "boolean"
  ) {
    return res.status(400).json({ error: "Missing or invalid fields" });
  }

  try {
    const submission = await createSubmission({
      topicId,
      attempts,
      guesses,
      duration,
      success,
    });

    return res.status(201).json(submission);
  } catch (error) {
    console.error("Error creating submission:", error);
    res.status(500).json({ error: "Internal server error." });
  }
};
