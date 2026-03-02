/**
 * PATCH /api/app/appointments/[id]/status
 * Body: { status: "pending" | "confirmed" | "in_progress" | "completed" | "cancelled" | "no_show" }
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

const VALID_STATUSES = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'] as const;

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { id } = await params;
  const body = await request.json();
  const { status } = body;

  if (!status || !VALID_STATUSES.includes(status)) {
    return NextResponse.json(
      { error: `status deve ser um de: ${VALID_STATUSES.join(', ')}` },
      { status: 400 }
    );
  }

  const appointment = await prisma.appointment.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!appointment) {
    return NextResponse.json({ error: 'Agendamento não encontrado' }, { status: 404 });
  }

  await prisma.appointment.update({
    where: { id },
    data: {
      status,
      confirmed: status === 'confirmed' ? true : appointment.confirmed,
    },
  });

  if (status === 'cancelled' && appointment.slot_id) {
    await prisma.slot.update({
      where: { id: appointment.slot_id },
      data: { status: 'available', appointment_id: null },
    });
  }

  const updated = await prisma.appointment.findUnique({
    where: { id },
    include: {
      barber: { select: { id: true, name: true, avatar_url: true } },
      service: { select: { id: true, name: true, price: true, duration_minutes: true } },
    },
  });

  return NextResponse.json(updated);
}
