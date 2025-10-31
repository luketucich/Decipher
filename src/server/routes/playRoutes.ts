import express from "express";
import {
  getDaily,
  getStats,
  submitGame,
} from "../controllers/playController.js";

const router = express.Router();

// GET /play/daily - Fetch today's topic with hints
router.get("/daily", getDaily);

// POST /play/submit - Submit player's attempt when they finish guessing
router.post("/submit", submitGame);

// GET /play/stats/:topicId - Get aggregated stats for a topic
router.get("/stats/:topicId", getStats);

export default router;
