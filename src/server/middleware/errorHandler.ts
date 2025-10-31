import { type ErrorRequestHandler } from "express";

/**
 * Global error handler middleware.
 * Catches unhandled errors and returns a standardized error response.
 */
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  const status = typeof err?.status === "number" ? err.status : 500;
  const message = err?.message ?? "Internal server error";

  if (process.env.NODE_ENV !== "production") {
    // eslint-disable-next-line no-console
    console.error("Unhandled error:", err);
  }

  res.status(status).json({ error: message });
};

export default errorHandler;
