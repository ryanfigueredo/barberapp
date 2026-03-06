/**
 * GET /api/app/appointments/month?month=YYYY-MM
 * Retorna dias do mês com agendamentos (para dots no calendário)
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const month = request.nextUrl.searchParams.get('month');
  if (!month || !/^\d{4}-\d{2}$/.test(month)) {
    return NextResponse.json(
      { error: 'Query month obrigatória no formato YYYY-MM' },
      { status: 400 }
    );
  }

  const barberId = request.nextUrl.searchParams.get('barber_id')?.trim() || null;

  const [year, monthNum] = month.split('-').map(Number);
  const startDate = new Date(Date.UTC(year, monthNum - 1, 1));
  const endDate = new Date(Date.UTC(year, monthNum, 0, 23, 59, 59));

  const appointments = await prisma.appointment.findMany({
    where: {
      tenant_id: tenant.id,
      appointment_date: { gte: startDate, lte: endDate },
      status: { notIn: ['cancelled'] },
      ...(barberId ? { barber_id: barberId } : {}),
    },
    select: { appointment_date: true, status: true },
  });

  const daysWithAppointments: Record<
    string,
    { count: number; statuses: string[] }
  > = {};

  for (const a of appointments) {
    const dateStr = a.appointment_date.toISOString().slice(0, 10);
    if (!daysWithAppointments[dateStr]) {
      daysWithAppointments[dateStr] = { count: 0, statuses: [] };
    }
    daysWithAppointments[dateStr].count++;
    if (!daysWithAppointments[dateStr].statuses.includes(a.status)) {
      daysWithAppointments[dateStr].statuses.push(a.status);
    }
  }

  return NextResponse.json({
    month,
    days_with_appointments: daysWithAppointments,
  });
}
