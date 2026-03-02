/**
 * GET / PATCH / DELETE serviço
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

  const service = await prisma.service.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!service) {
    return NextResponse.json({ error: 'Serviço não encontrado' }, { status: 404 });
  }

  return NextResponse.json(service);
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

  const service = await prisma.service.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!service) {
    return NextResponse.json({ error: 'Serviço não encontrado' }, { status: 404 });
  }

  const updated = await prisma.service.update({
    where: { id },
    data: {
      name: body.name ?? service.name,
      price: body.price ?? service.price,
      duration_minutes: body.duration_minutes ?? service.duration_minutes,
      active: body.active ?? service.active,
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

  const service = await prisma.service.findFirst({
    where: { id, tenant_id: tenant.id },
  });

  if (!service) {
    return NextResponse.json({ error: 'Serviço não encontrado' }, { status: 404 });
  }

  await prisma.service.update({
    where: { id },
    data: { active: false },
  });

  return NextResponse.json({ success: true });
}
