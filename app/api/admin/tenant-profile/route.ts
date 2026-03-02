/**
 * GET /api/admin/tenant-profile — perfil da barbearia
 * PATCH /api/admin/tenant-profile — atualizar perfil
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const full = await prisma.tenant.findUnique({
    where: { id: tenant.id },
    select: {
      id: true,
      name: true,
      slug: true,
      business_name: true,
      logo_url: true,
      address: true,
      opening_time: true,
      closing_time: true,
      slot_duration_minutes: true,
      whatsapp_phone: true,
      bot_configured: true,
      plan_type: true,
      plan_active: true,
    },
  });

  if (!full) {
    return NextResponse.json({ error: 'Tenant não encontrado' }, { status: 404 });
  }

  return NextResponse.json(full);
}

export async function PATCH(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const allowed = [
      'name',
      'business_name',
      'logo_url',
      'address',
      'opening_time',
      'closing_time',
      'slot_duration_minutes',
      'whatsapp_phone',
    ];

    const data: Record<string, unknown> = {};
    for (const key of allowed) {
      if (body[key] !== undefined) {
        data[key] = body[key];
      }
    }

    const updated = await prisma.tenant.update({
      where: { id: tenant.id },
      data,
    });

    return NextResponse.json({
      id: updated.id,
      name: updated.name,
      slug: updated.slug,
      business_name: updated.business_name,
      logo_url: updated.logo_url,
      address: updated.address,
      opening_time: updated.opening_time,
      closing_time: updated.closing_time,
      slot_duration_minutes: updated.slot_duration_minutes,
    });
  } catch (error) {
    console.error('[PATCH tenant-profile]', error);
    return NextResponse.json({ error: 'Erro ao atualizar perfil' }, { status: 500 });
  }
}
