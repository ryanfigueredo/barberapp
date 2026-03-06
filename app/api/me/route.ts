/**
 * GET /api/me — usuário atual (para checagem de acesso ex: /prices)
 * Requer sessão (cookie) ou api_key; com sessão retorna username.
 */

import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { prisma } from '@/lib/prisma';

export async function GET(request: NextRequest) {
  const sessionCookie = (await cookies()).get('session')?.value;
  if (sessionCookie) {
    try {
      const decoded = Buffer.from(sessionCookie, 'base64').toString('utf-8');
      const session = JSON.parse(decoded) as { userId?: string; username?: string; tenantId?: string; role?: string; barberId?: string };
      if (session.userId && session.username) {
        const user = await prisma.user.findUnique({
          where: { id: session.userId },
          select: { id: true, username: true, name: true, role: true, tenant_id: true, barber_id: true },
        });
        if (user) {
          return NextResponse.json({
            user: {
              id: user.id,
              username: user.username,
              name: user.name,
              role: user.role,
              tenant_id: user.tenant_id,
              barber_id: user.barber_id,
            },
          });
        }
      }
    } catch {
      // ignore
    }
  }

  const apiKey = request.headers.get('x-api-key');
  if (apiKey) {
    const tenant = await prisma.tenant.findUnique({
      where: { api_key: apiKey, plan_active: true },
      select: { id: true, name: true },
    });
    if (tenant) {
      return NextResponse.json({ user: null, tenant: { id: tenant.id, name: tenant.name } });
    }
  }

  return NextResponse.json({ user: null }, { status: 200 });
}
