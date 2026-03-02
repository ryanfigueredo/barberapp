/**
 * GET /api/app/appointments/[id]
 * DELETE /api/app/appointments/[id]
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { id } = await params;

  const appointment = await prisma.appointment.findFirst({
    where: { id, tenant_id: tenant.id },
    include: {
      barber: { select: { id: true, name: true, avatar_url: true } },
      service: { select: { id: true, name: true, price: true, duration_minutes: true } },
    },
  });

  if (!appointment) {
    return NextResponse.json({ error: 'Agendamento não encontrado' }, { status: 404 });
  }

  return NextResponse.json({
    ...appointment,
    appointment_date: appointment.appointment_date.toISOString(),
    barber: appointment.barber
      ? {
          id: appointment.barber.id,
          name: appointment.barber.name,
          avatar_url: appointment.barber.avatar_url,
        }
      : null,
    service: appointment.service,
  });
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { id } = await params;

  const appointment = await prisma.appointment.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!appointment) {
    return NextResponse.json({ error: 'Agendamento não encontrado' }, { status: 404 });
  }

  await prisma.$transaction(async (tx) => {
    await tx.appointment.update({
      where: { id },
      data: { status: 'cancelled' },
    });
    if (appointment.slot_id) {
      await tx.slot.update({
        where: { id: appointment.slot_id },
        data: { status: 'available', appointment_id: null },
      });
    }
  });

  return NextResponse.json({ success: true });
}
