/**
 * POST /api/admin/whatsapp/attendant-request/resolve
 * Marca o pedido de atendente como resolvido para um customer_phone (quando o atendente assume a conversa).
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  return d.startsWith('55') ? d : '55' + d;
}

export async function POST(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const body = await request.json().catch(() => ({}));
  const customer_phone = body.customer_phone?.trim();
  if (!customer_phone) {
    return NextResponse.json({ error: 'customer_phone obrigatório' }, { status: 400 });
  }

  const phoneNorm = normalizePhone(customer_phone);

  try {
    await prisma.whatsAppAttendantRequest.updateMany({
      where: {
        tenant_id: auth.tenant.id,
        customer_phone: phoneNorm,
        resolved_at: null,
      },
      data: { resolved_at: new Date() },
    });
    return NextResponse.json({ success: true });
  } catch (e) {
    console.error('[POST attendant-request/resolve]', e);
    return NextResponse.json({ error: 'Erro ao marcar como resolvido' }, { status: 500 });
  }
}
