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
    // Accept client's local date as YYYY-MM-DD query param, default to UTC date
    const clientDate = req.query.date as string | undefined;
    let today: Date;

    if (clientDate && /^\d{4}-\d{2}-\d{2}$/.test(clientDate)) {
      const parts = clientDate.split("-");
      const year = Number(parts[0]);
      const month = Number(parts[1]);
      const day = Number(parts[2]);
      today = new Date(Date.UTC(year, month - 1, day));
    } else {
      const now = new Date();
      today = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())
      );
    }

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
