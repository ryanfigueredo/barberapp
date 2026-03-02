/**
 * CRUD barbeiros
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const barbers = await prisma.barber.findMany({
    where: { tenant_id: tenant.id },
    orderBy: { name: 'asc' },
  });

  return NextResponse.json(barbers);
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { name, phone, avatar_url } = body;

    if (!name) {
      return NextResponse.json({ error: 'name obrigatório' }, { status: 400 });
    }

    const barber = await prisma.barber.create({
      data: {
        tenant_id: tenant.id,
        name,
        phone: phone || null,
        avatar_url: avatar_url || null,
        active: true,
      },
    });

    return NextResponse.json(barber);
  } catch (error) {
    console.error('[POST barbers]', error);
    return NextResponse.json({ error: 'Erro ao criar barbeiro' }, { status: 500 });
  }
}
