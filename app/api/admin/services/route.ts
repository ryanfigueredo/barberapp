/**
 * CRUD serviços
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const services = await prisma.service.findMany({
    where: { tenant_id: tenant.id },
    orderBy: { name: 'asc' },
  });

  return NextResponse.json(services);
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { name, price, duration_minutes } = body;

    if (!name || price === undefined) {
      return NextResponse.json({ error: 'name e price obrigatórios' }, { status: 400 });
    }

    const service = await prisma.service.create({
      data: {
        tenant_id: tenant.id,
        name,
        price: Number(price),
        duration_minutes: duration_minutes ?? 60,
        active: true,
      },
    });

    return NextResponse.json(service);
  } catch (error) {
    console.error('[POST services]', error);
    return NextResponse.json({ error: 'Erro ao criar serviço' }, { status: 500 });
  }
}
