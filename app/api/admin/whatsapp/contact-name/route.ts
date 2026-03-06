/**
 * PUT /api/admin/whatsapp/contact-name
 * Body: { customer_phone: string, display_name: string }
 * Cria ou atualiza o nome de exibição do cliente (usado no painel e pelo bot).
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  return d.startsWith('55') ? d : '55' + d;
}

export async function PUT(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  let body: { customer_phone?: string; display_name?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Body JSON inválido' }, { status: 400 });
  }

  const rawPhone = body.customer_phone?.trim();
  const displayName = body.display_name?.trim();
  if (!rawPhone || displayName === undefined || displayName === '') {
    return NextResponse.json(
      { error: 'customer_phone e display_name são obrigatórios' },
      { status: 400 }
    );
  }

  const customer_phone = normalizePhone(rawPhone);

  await prisma.whatsAppContactName.upsert({
    where: {
      tenant_id_customer_phone: {
        tenant_id: auth.tenant.id,
        customer_phone,
      },
    },
    create: {
      tenant_id: auth.tenant.id,
      customer_phone,
      display_name: displayName,
    },
    update: { display_name: displayName },
  });

  return NextResponse.json({ ok: true, customer_phone, display_name: displayName });
}
