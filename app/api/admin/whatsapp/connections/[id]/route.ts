/**
 * PATCH /api/admin/whatsapp/connections/[id] — atualiza conexão
 * DELETE /api/admin/whatsapp/connections/[id] — remove conexão
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { id } = await params;
  const connection = await prisma.tenantWhatsApp.findFirst({
    where: { id, tenant_id: tenant.id },
  });
  if (!connection) {
    return NextResponse.json({ error: 'Conexão não encontrada' }, { status: 404 });
  }

  try {
    const body = await request.json();
    const { whatsapp_phone, meta_phone_number_id, meta_access_token, meta_business_account_id, barber_id } = body;

    const data: Record<string, unknown> = {};
    if (whatsapp_phone !== undefined) data.whatsapp_phone = whatsapp_phone?.trim() || null;
    if (meta_phone_number_id !== undefined) data.meta_phone_number_id = String(meta_phone_number_id);
    if (meta_access_token !== undefined) data.meta_access_token = String(meta_access_token);
    if (meta_business_account_id !== undefined) data.meta_business_account_id = meta_business_account_id?.trim() || null;
    if (barber_id !== undefined) {
      if (barber_id) {
        const barber = await prisma.barber.findFirst({
          where: { id: barber_id, tenant_id: tenant.id },
        });
        if (!barber) {
          return NextResponse.json({ error: 'Barbeiro não encontrado' }, { status: 404 });
        }
      }
      data.barber_id = barber_id || null;
    }

    const updated = await prisma.tenantWhatsApp.update({
      where: { id },
      data,
      include: { barber: { select: { id: true, name: true } } },
    });

    return NextResponse.json({
      id: updated.id,
      barber_id: updated.barber_id,
      barber: updated.barber,
      whatsapp_phone: updated.whatsapp_phone,
      meta_phone_number_id: updated.meta_phone_number_id,
      bot_configured: updated.bot_configured,
    });
  } catch (error) {
    console.error('[PATCH whatsapp/connections]', error);
    return NextResponse.json({ error: 'Erro ao atualizar' }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const tenant = await getTenantFromRequest(_request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const { id } = await params;
  const connection = await prisma.tenantWhatsApp.findFirst({
    where: { id, tenant_id: tenant.id },
  });
  if (!connection) {
    return NextResponse.json({ error: 'Conexão não encontrada' }, { status: 404 });
  }

  await prisma.tenantWhatsApp.delete({ where: { id } });
  return NextResponse.json({ success: true });
}
