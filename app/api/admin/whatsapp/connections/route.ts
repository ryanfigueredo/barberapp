/**
 * GET /api/admin/whatsapp/connections — lista conexões WhatsApp do tenant
 * POST /api/admin/whatsapp/connections — cria conexão (geral ou por barbeiro)
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const connections = await prisma.tenantWhatsApp.findMany({
    where: { tenant_id: tenant.id },
    include: { barber: { select: { id: true, name: true } } },
    orderBy: [{ barber_id: 'asc' }, { created_at: 'asc' }],
  });

  return NextResponse.json({
    connections: connections.map((c) => ({
      id: c.id,
      tenant_id: c.tenant_id,
      barber_id: c.barber_id,
      barber: c.barber ? { id: c.barber.id, name: c.barber.name } : null,
      whatsapp_phone: c.whatsapp_phone,
      meta_phone_number_id: c.meta_phone_number_id,
      bot_configured: c.bot_configured,
      created_at: c.created_at,
    })),
  });
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { barber_id, whatsapp_phone, meta_phone_number_id, meta_access_token, meta_business_account_id } = body;

    if (!meta_phone_number_id || !meta_access_token) {
      return NextResponse.json(
        { error: 'meta_phone_number_id e meta_access_token são obrigatórios' },
        { status: 400 }
      );
    }

    if (barber_id) {
      const barber = await prisma.barber.findFirst({
        where: { id: barber_id, tenant_id: tenant.id },
      });
      if (!barber) {
        return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
      }
    }

    const existing = await prisma.tenantWhatsApp.findUnique({
      where: { meta_phone_number_id: String(meta_phone_number_id) },
    });
    if (existing) {
      return NextResponse.json(
        { error: 'Este número já está vinculado a outra conta' },
        { status: 400 }
      );
    }

    const connection = await prisma.tenantWhatsApp.create({
      data: {
        tenant_id: tenant.id,
        barber_id: barber_id || null,
        whatsapp_phone: whatsapp_phone?.trim() || null,
        meta_phone_number_id: String(meta_phone_number_id),
        meta_access_token: String(meta_access_token),
        meta_business_account_id: meta_business_account_id?.trim() || null,
        bot_configured: true,
      },
      include: { barber: { select: { id: true, name: true } } },
    });

    return NextResponse.json({
      id: connection.id,
      barber_id: connection.barber_id,
      barber: connection.barber,
      whatsapp_phone: connection.whatsapp_phone,
      meta_phone_number_id: connection.meta_phone_number_id,
      bot_configured: connection.bot_configured,
      created_at: connection.created_at,
    });
  } catch (error) {
    console.error('[POST whatsapp/connections]', error);
    return NextResponse.json({ error: 'Erro ao criar conexão' }, { status: 500 });
  }
}
