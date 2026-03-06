/**
 * GET /api/admin/whatsapp/messages?customer_phone=5521999999999
 * Lista mensagens de uma conversa (ordenado por created_at).
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const customer_phone = request.nextUrl.searchParams.get('customer_phone')?.trim();
  if (!customer_phone) {
    return NextResponse.json({ error: 'customer_phone obrigatório' }, { status: 400 });
  }

  const phoneNorm = customer_phone.replace(/\D/g, '').replace(/^55/, '') || customer_phone;
  const messages = await prisma.botMessage.findMany({
    where: {
      tenant_id: auth.tenant.id,
      customer_phone: phoneNorm,
    },
    orderBy: { created_at: 'asc' },
    select: {
      id: true,
      direction: true,
      body: true,
      is_bot: true,
      created_at: true,
    },
  });

  const normalized = messages.map((m) => ({
    id: m.id,
    direction: m.direction,
    body: m.body,
    is_bot: m.is_bot,
    created_at: m.created_at.toISOString(),
  }));

  return NextResponse.json({ messages: normalized });
}
