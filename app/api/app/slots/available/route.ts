/**
 * GET /api/app/slots/available?date=YYYY-MM-DD&barber_id=
 * Retorna slots disponíveis do dia
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const date = request.nextUrl.searchParams.get('date');
  const barberId = request.nextUrl.searchParams.get('barber_id');

  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json(
      { error: 'Query date obrigatória no formato YYYY-MM-DD' },
      { status: 400 }
    );
  }

  const startOfDay = new Date(date + 'T00:00:00.000Z');
  const endOfDay = new Date(date + 'T23:59:59.999Z');

  const where: Record<string, unknown> = {
    tenant_id: tenant.id,
    status: 'available',
    start_time: { gte: startOfDay, lte: endOfDay },
  };
  if (barberId) where.barber_id = barberId;

  const slots = await prisma.slot.findMany({
    where,
    include: {
      barber: { select: { id: true, name: true, avatar_url: true } },
    },
    orderBy: { start_time: 'asc' },
  });

  const formatted = slots.map((s) => ({
    id: s.id,
    start_time: s.start_time.toISOString(),
    end_time: s.end_time.toISOString(),
    time: s.start_time.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
    barber: s.barber,
  }));

  return NextResponse.json({ slots: formatted });
}
