/**
 * GET /api/app/appointments
 * Query: ?date=YYYY-MM-DD | ?barber_id= | ?status= | ?upcoming=true
 * POST /api/app/appointments — criar agendamento
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { searchParams } = request.nextUrl;
  const date = searchParams.get('date');
  const startParam = searchParams.get('start');
  const endParam = searchParams.get('end');
  const barberIdParam = searchParams.get('barber_id');
  const statusFilter = searchParams.get('status');
  const upcoming = searchParams.get('upcoming') === 'true';

  const where: Record<string, unknown> = { tenant_id: auth.tenant.id };
  if (auth.barberId) where.barber_id = auth.barberId;
  if (barberIdParam && !auth.barberId) where.barber_id = barberIdParam;
  if (statusFilter) {
    const statuses = statusFilter.split(',').map((s) => s.trim());
    where.status = { in: statuses };
  }
  if (startParam && endParam) {
    const start = new Date(startParam + 'T00:00:00.000Z');
    const end = new Date(endParam + 'T23:59:59.999Z');
    where.appointment_date = { gte: start, lte: end };
  } else if (date) {
    const start = new Date(date + 'T00:00:00.000Z');
    const end = new Date(date + 'T23:59:59.999Z');
    where.appointment_date = { gte: start, lte: end };
  }
  if (upcoming) {
    const now = new Date();
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    where.appointment_date = { gte: now, lte: nextWeek };
  }

  const appointments = await prisma.appointment.findMany({
    where,
    include: {
      barber: { select: { id: true, name: true, avatar_url: true } },
      service: { select: { id: true, name: true, price: true, duration_minutes: true } },
    },
    orderBy: { appointment_date: 'asc' },
  });

  const formatted = appointments.map((a) => ({
    id: a.id,
    customer_name: a.customer_name,
    customer_phone: a.customer_phone,
    appointment_date: a.appointment_date.toISOString(),
    status: a.status,
    barber: {
      id: a.barber.id,
      name: a.barber.name,
      avatar_url: a.barber.avatar_url,
    },
    service: a.service,
    customer_notes: a.customer_notes,
    barber_notes: a.barber_notes,
    origin: a.origin,
    confirmed: a.confirmed,
    reminder_sent: a.reminder_sent,
  }));

  return NextResponse.json({
    appointments: formatted,
    date: date ?? null,
    total: formatted.length,
  });
}

export async function POST(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }
  const tenant = auth.tenant;

  try {
    const body = await request.json();
    const { barber_id, service_id, slot_id, customer_name, customer_phone, appointment_date, customer_notes } =
      body;

    if (!barber_id || !customer_name || !customer_phone || !appointment_date) {
      return NextResponse.json(
        { error: 'barber_id, customer_name, customer_phone, appointment_date obrigatórios' },
        { status: 400 }
      );
    }

    const apptDate = new Date(appointment_date);

    let slotId = slot_id;
    if (!slotId) {
      const slotDuration = 60; // TODO: usar do service ou tenant
      const startTime = new Date(apptDate);
      const endTime = new Date(apptDate.getTime() + slotDuration * 60 * 1000);
      const existingSlot = await prisma.slot.findFirst({
        where: {
          tenant_id: tenant.id,
          barber_id,
          status: 'available',
          start_time: startTime,
        },
      });
      if (existingSlot) slotId = existingSlot.id;
    }

    const appointment = await prisma.$transaction(async (tx) => {
      const appt = await tx.appointment.create({
        data: {
          tenant_id: tenant.id,
          barber_id,
          service_id: service_id || null,
          slot_id: slotId || null,
          customer_name,
          customer_phone,
          appointment_date: apptDate,
          customer_notes: customer_notes || null,
          status: 'pending',
          origin: 'app',
        },
      });

      if (slotId) {
        await tx.slot.update({
          where: { id: slotId },
          data: { status: 'booked', appointment_id: appt.id },
        });
      }

      return appt;
    });

    const full = await prisma.appointment.findUnique({
      where: { id: appointment.id },
      include: {
        barber: { select: { id: true, name: true, avatar_url: true } },
        service: { select: { id: true, name: true, price: true, duration_minutes: true } },
      },
    });

    return NextResponse.json({
      ...full,
      barber: full?.barber ? { id: full.barber.id, name: full.barber.name, avatar_url: full.barber.avatar_url } : null,
      service: full?.service,
    });
  } catch (error) {
    console.error('[POST appointments]', error);
    return NextResponse.json({ error: 'Erro ao criar agendamento' }, { status: 500 });
  }
}
