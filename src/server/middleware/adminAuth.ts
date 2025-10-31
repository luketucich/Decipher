import { type NextFunction, type Request, type Response } from "express";

/**
 * Admin authentication middleware.
 * Validates admin token from x-admin-token header or Authorization Bearer token.
 */

const HEADER_NAME = "x-admin-token";

export default function adminAuth(req: Request, res: Response, next: NextFunction) {
  const headerToken = req.header(HEADER_NAME);
  const bearer = req.header("authorization");
  const bearerToken = bearer?.startsWith("Bearer ") ? bearer.slice(7) : undefined;

  const token = headerToken || bearerToken;
  if (!process.env.ADMIN_TOKEN) {
    return res.status(500).json({ error: "Server misconfigured: ADMIN_TOKEN missing" });
  }
  if (token !== process.env.ADMIN_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  return next();
}
