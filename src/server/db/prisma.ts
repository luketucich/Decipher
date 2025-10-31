import { PrismaClient } from "@prisma/client";

/**
 * Prisma client singleton.
 * In development, reuses the same instance across hot reloads to avoid
 * "too many clients" errors.
 */

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalThis.prisma = prisma;
}
