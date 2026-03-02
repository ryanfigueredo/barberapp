/**
 * POST /api/admin/slots/generate
 * Gera slots automaticamente para a semana
 *
 * Body:
 * {
 *   barber_id: string,
 *   start_date: "YYYY-MM-DD",
 *   end_date: "YYYY-MM-DD",
 *   daily_start: "09:00",
 *   daily_end: "20:00",
 *   slot_duration_minutes: 60,
 *   break_times: [{ start: "12:00", end: "13:00" }],
 *   days_of_week: [1,2,3,4,5,6] // 0=dom, 6=sab
 * }
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

function parseTime(timeStr: string): { hour: number; minute: number } {
  const [h, m] = timeStr.split(':').map(Number);
  return { hour: h ?? 9, minute: m ?? 0 };
}

function isInBreak(start: Date, breakTimes: { start: string; end: string }[]): boolean {
  const startHour = start.getHours();
  const startMin = start.getMinutes();
  const startMins = startHour * 60 + startMin;

  for (const brk of breakTimes) {
    const [sH, sM] = brk.start.split(':').map(Number);
    const [eH, eM] = brk.end.split(':').map(Number);
    const breakStart = sH * 60 + sM;
    const breakEnd = eH * 60 + eM;
    if (startMins >= breakStart && startMins < breakEnd) return true;
  }
  return false;
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const {
      barber_id,
      start_date,
      end_date,
      daily_start = '09:00',
      daily_end = '20:00',
      slot_duration_minutes = 60,
      break_times = [],
      days_of_week = [1, 2, 3, 4, 5, 6],
    } = body;

    if (!barber_id || !start_date || !end_date) {
      return NextResponse.json(
        { error: 'barber_id, start_date, end_date obrigatórios' },
        { status: 400 }
      );
    }

    const barber = await prisma.barber.findFirst({
      where: { id: barber_id, tenant_id: tenant.id },
    });
    if (!barber) {
      return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
    }

    const startDate = new Date(start_date);
    const endDate = new Date(end_date);
    const { hour: startHour, minute: startMin } = parseTime(daily_start);
    const { hour: endHour, minute: endMin } = parseTime(daily_end);
    const slotDuration = Number(slot_duration_minutes) || 60;

    const created: string[] = [];
    let current = new Date(startDate);

    while (current <= endDate) {
      const dayOfWeek = current.getDay();
      if (!days_of_week.includes(dayOfWeek)) {
        current.setDate(current.getDate() + 1);
        continue;
      }

      let slotStart = new Date(current);
      slotStart.setHours(startHour, startMin, 0, 0);
      const dayEnd = new Date(current);
      dayEnd.setHours(endHour, endMin, 0, 0);

      while (slotStart < dayEnd) {
        if (!isInBreak(slotStart, break_times)) {
          const slotEnd = new Date(slotStart.getTime() + slotDuration * 60 * 1000);
          if (slotEnd <= dayEnd) {
            const existing = await prisma.slot.findFirst({
              where: {
                tenant_id: tenant.id,
                barber_id,
                start_time: slotStart,
                status: 'available',
              },
            });

            if (!existing) {
              const slot = await prisma.slot.create({
                data: {
                  tenant_id: tenant.id,
                  barber_id,
                  start_time: new Date(slotStart),
                  end_time: slotEnd,
                  status: 'available',
                },
              });
              created.push(slot.id);
            }
          }
        }

        slotStart.setMinutes(slotStart.getMinutes() + slotDuration);
      }

      current.setDate(current.getDate() + 1);
    }

    return NextResponse.json({
      success: true,
      created: created.length,
      slot_ids: created,
    });
  } catch (error) {
    console.error('[POST slots/generate]', error);
    return NextResponse.json({ error: 'Erro ao gerar slots' }, { status: 500 });
  }
}
