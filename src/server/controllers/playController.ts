import { type Request, type Response } from "express";
import { createSubmission } from "../repositories/submissionRepository.js";
import {
  getTopicByDate,
  getTopicNumber,
} from "../repositories/topicRepository.js";

/**
 * GET /play/daily
 * Fetches today's daily topic with hints ordered by hint order.
 */
export const getDaily = async (req: Request, res: Response) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()); // Local midnight
    const topic = await getTopicByDate(today);

    if (!topic) {
      return res.status(404).json({ error: "No topic found for today" });
    }

    const topicNumber = await getTopicNumber(today);

    return res.status(200).json({ ...topic, topicNumber });
  } catch (error) {
    console.error("Error fetching daily topic:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

/**
 * POST /play/submit
 * Submits a completed game result (win or loss).
 */
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
    res.status(500).json({ error: "Internal server error" });
  }
};
