/**
 * GET / PATCH / DELETE barbeiro
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

  const barber = await prisma.barber.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!barber) {
    return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
  }

  return NextResponse.json(barber);
}

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

  const barber = await prisma.barber.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!barber) {
    return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
  }

  const updated = await prisma.barber.update({
    where: { id },
    data: {
      name: body.name ?? barber.name,
      phone: body.phone ?? barber.phone,
      avatar_url: body.avatar_url ?? barber.avatar_url,
      active: body.active ?? barber.active,
    },
  });

  return NextResponse.json(updated);
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

  const barber = await prisma.barber.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!barber) {
    return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
  }

  await prisma.barber.update({
    where: { id },
    data: { active: false },
  });

  return NextResponse.json({ success: true });
}
