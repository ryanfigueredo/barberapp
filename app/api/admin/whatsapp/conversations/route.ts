/**
 * GET /api/admin/whatsapp/conversations
 * Lista conversas (agrupado por customer_phone) com última mensagem, total e display_name (se cadastrado).
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getAuthFromRequest } from '@/lib/auth';

function normalizePhoneForKey(phone: string): string {
  const d = phone.replace(/\D/g, '');
  return d.startsWith('55') ? d : '55' + d;
}

export async function GET(request: NextRequest) {
  const auth = await getAuthFromRequest(request);
  if (!auth.tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const raw = await prisma.botMessage.findMany({
    where: { tenant_id: auth.tenant.id },
    select: { customer_phone: true, body: true, direction: true, created_at: true },
    orderBy: { created_at: 'desc' },
  });

  const byPhone = new Map<
    string,
    { customer_phone: string; last_body: string; last_at: string; last_direction: string; count: number; display_name?: string | null }
  >();
  for (const m of raw) {
    const key = m.customer_phone;
    if (!byPhone.has(key)) {
      byPhone.set(key, {
        customer_phone: key,
        last_body: m.body.slice(0, 80),
        last_at: m.created_at.toISOString(),
        last_direction: m.direction,
        count: 0,
      });
    }
    const entry = byPhone.get(key)!;
    entry.count += 1;
  }

  const phones = Array.from(byPhone.keys()).map(normalizePhoneForKey);
  const contactNames = await prisma.whatsAppContactName.findMany({
    where: { tenant_id: auth.tenant.id, customer_phone: { in: phones } },
    select: { customer_phone: true, display_name: true },
  });
  const nameByPhone = new Map(contactNames.map((c) => [c.customer_phone, c.display_name]));

  for (const entry of Array.from(byPhone.values())) {
    const normalized = normalizePhoneForKey(entry.customer_phone);
    entry.display_name = nameByPhone.get(normalized) ?? null;
  }

  const conversations = Array.from(byPhone.values()).sort(
    (a, b) => new Date(b.last_at).getTime() - new Date(a.last_at).getTime()
  );

  return NextResponse.json({ conversations });
}
