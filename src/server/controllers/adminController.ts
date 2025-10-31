import { type Request, type Response } from "express";
import { createTopic as createTopicRepo } from "../repositories/topicRepository.js";

/**
 * POST /admin/topic
 * Creates a new daily topic with hints (admin only).
 * Requires admin authentication via x-admin-token header or Bearer token.
 */
export const createTopic = async (req: Request, res: Response) => {
  const { answer, date, type, hints } = req.body;

  if (
    !answer ||
    !date ||
    !type ||
    !Array.isArray(hints) ||
    hints.length === 0
  ) {
    return res.status(400).json({
      error:
        "Missing or invalid fields (answer: string, date: string (YYYY-MM-DD), type: string, hints: array of {content, type, order})",
    });
  }

  try {
    // Convert date string (YYYY-MM-DD) to Date object at local midnight
    const [year, month, day] = date.split("-").map(Number);
    const topicDate = new Date(year, month - 1, day); // month is 0-indexed
    if (isNaN(topicDate.getTime())) {
      return res.status(400).json({ error: "Invalid date format" });
    }

    const newTopic = await createTopicRepo({
      answer,
      date: topicDate,
      type,
      hints,
    });

    res.status(201).json(newTopic);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};
