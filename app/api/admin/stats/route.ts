/**
 * GET /api/admin/stats — estatísticas do dashboard
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const tenant = auth.tenant;
  const barberFilter = auth.barberId ? { barber_id: auth.barberId } : {};

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6);
  endOfWeek.setHours(23, 59, 59, 999);

  const [todayCount, weekCount, upcomingToday, barberCount, completedToday, completedWeek] = await Promise.all([
    prisma.appointment.count({
      where: {
        tenant_id: tenant.id,
        ...barberFilter,
        appointment_date: { gte: startOfToday, lte: endOfToday },
        status: { notIn: ['cancelled', 'no_show'] },
      },
    }),
    prisma.appointment.count({
      where: {
        tenant_id: tenant.id,
        ...barberFilter,
        appointment_date: { gte: startOfWeek, lte: endOfWeek },
        status: { notIn: ['cancelled', 'no_show'] },
      },
    }),
    prisma.appointment.findMany({
      where: {
        tenant_id: tenant.id,
        ...barberFilter,
        appointment_date: { gte: now, lte: endOfToday },
        status: { notIn: ['cancelled', 'no_show'] },
      },
      include: {
        barber: { select: { id: true, name: true } },
        service: { select: { id: true, name: true, price: true } },
      },
      orderBy: { appointment_date: 'asc' },
      take: 10,
    }),
    prisma.barber.count({
      where: { tenant_id: tenant.id, active: true, ...(auth.barberId ? { id: auth.barberId } : {}) },
    }),
    prisma.appointment.findMany({
      where: {
        tenant_id: tenant.id,
        ...barberFilter,
        appointment_date: { gte: startOfToday, lte: endOfToday },
        status: 'completed',
      },
      include: { service: { select: { price: true } } },
    }),
    prisma.appointment.findMany({
      where: {
        tenant_id: tenant.id,
        ...barberFilter,
        appointment_date: { gte: startOfWeek, lte: endOfWeek },
        status: 'completed',
      },
      include: { service: { select: { price: true } } },
    }),
  ]);

  const revenue_today = completedToday.reduce((s, a) => s + (Number(a.service?.price) || 0), 0);
  const revenue_week = completedWeek.reduce((s, a) => s + (Number(a.service?.price) || 0), 0);

  return NextResponse.json({
    today: todayCount,
    week: weekCount,
    barbers: barberCount,
    revenue_today,
    revenue_week,
    upcoming_today: upcomingToday.map((a) => ({
      id: a.id,
      customer_name: a.customer_name,
      appointment_date: a.appointment_date.toISOString(),
      status: a.status,
      barber: a.barber,
      service: a.service,
    })),
  });
}
