import express from "express";
import { getDaily, submitGame } from "../controllers/playController.js";

const router = express.Router();

// GET /play/daily - Fetch today's topic with hints
router.get("/daily", getDaily);

// POST /play/submit - Submit player's attempt when they finish guessing
router.post("/submit", submitGame);

export default router;
