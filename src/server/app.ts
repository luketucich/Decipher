import compression from "compression";
import cors, { type CorsOptions } from "cors";
import "dotenv/config";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import morgan from "morgan";

import { prisma } from "./db/prisma.js";
import adminAuth from "./middleware/adminAuth.js";
import errorHandler from "./middleware/errorHandler.js";
import adminRoutes from "./routes/adminRoutes.js";
import playRoutes from "./routes/playRoutes.js";

const app = express();
const PORT = Number.parseInt(process.env.PORT ?? "3000", 10);

// Trust proxy when behind load balancers (Heroku/Render/Nginx)
app.set("trust proxy", 1);

// Security and performance middlewares
app.use(helmet());
app.use(compression());

// CORS configuration (set CORS_ORIGINS env as comma-separated list)
const envOrigins = (process.env.CORS_ORIGINS ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);
const defaultOrigins = [
  "https://deciphergame.com",
  "https://www.deciphergame.com",
  "http://localhost:3000",
  "http://localhost:5173",
  "https://decipher-wdx2.onrender.com",
];
const corsOptions: CorsOptions = {
  origin: envOrigins.length ? envOrigins : defaultOrigins,
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Logging
app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));

// Body parsing
app.use(express.json({ limit: "100kb" }));

// Health check
app.get("/healthz", (_req, res) => res.status(200).send("ok"));

// Routes
app.use("/play", playRoutes);
app.use("/admin", adminAuth, adminRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// Error handler
app.use(errorHandler);

const server = app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

async function gracefulShutdown(signal: string) {
  console.log(`${signal} received, shutting down gracefully...`);
  server.close(async () => {
    try {
      await prisma.$disconnect();
    } finally {
      process.exit(0);
    }
  });
  // Fallback if close hangs
  setTimeout(() => {
    console.warn("Force exiting after timeout");
    process.exit(1);
  }, 10_000).unref();
}

process.on("SIGINT", () => void gracefulShutdown("SIGINT"));
process.on("SIGTERM", () => void gracefulShutdown("SIGTERM"));

export default app;
