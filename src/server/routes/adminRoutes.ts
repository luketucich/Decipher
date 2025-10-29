import express from "express";
import { createTopic } from "../controllers/adminController.js";

const router = express.Router();

// POST /admin/topic - Create a new topic (admin only)
router.post("/topic", createTopic);

export default router;
