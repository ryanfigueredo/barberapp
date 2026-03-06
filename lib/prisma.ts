import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    // Em dev: só error/warn para não encher o terminal. Para ver as queries, use DEBUG=prisma:query
    log: process.env.NODE_ENV === 'development'
      ? process.env.DEBUG?.includes('prisma')
        ? ['query', 'error', 'warn']
        : ['error', 'warn']
      : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
