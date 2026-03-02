/**
 * GET /api/admin/slots — lista slots
 * POST /api/admin/slots — criar slot manual
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

  const where: Record<string, unknown> = { tenant_id: tenant.id };
  if (date) {
    const start = new Date(date + 'T00:00:00.000Z');
    const end = new Date(date + 'T23:59:59.999Z');
    where.start_time = { gte: start, lte: end };
  }
  if (barberId) where.barber_id = barberId;

  const slots = await prisma.slot.findMany({
    where,
    include: {
      barber: { select: { id: true, name: true } },
      appointment: { select: { id: true, customer_name: true } },
    },
    orderBy: { start_time: 'asc' },
  });

  return NextResponse.json(slots);
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { barber_id, start_time, end_time, status } = body;

    if (!barber_id || !start_time || !end_time) {
      return NextResponse.json({ error: 'barber_id, start_time, end_time obrigatórios' }, { status: 400 });
    }

    const barber = await prisma.barber.findFirst({
      where: { id: barber_id, tenant_id: tenant.id },
    });
    if (!barber) {
      return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
    }

    const slot = await prisma.slot.create({
      data: {
        tenant_id: tenant.id,
        barber_id,
        start_time: new Date(start_time),
        end_time: new Date(end_time),
        status: status || 'available',
      },
    });

    return NextResponse.json(slot);
  } catch (error) {
    console.error('[POST slots]', error);
    return NextResponse.json({ error: 'Erro ao criar slot' }, { status: 500 });
  }
}
