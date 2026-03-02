/**
 * POST /api/admin/whatsapp/send
 * Envia mensagem WhatsApp para um número (ex.: aviso de cancelamento).
 * Body: { "phone": "5511999999999", "message": "Seu agendamento foi desmarcado. Motivo: ..." }
 */

import { NextRequest, NextResponse } from 'next/server';
import { getTenantFromRequest } from '@/lib/auth';
import { sendWhatsAppMessageFromTenant } from '@/lib/whatsapp-bot/barber-bot-handler';

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const phone = body.phone as string | undefined;
    const message = body.message as string | undefined;

    if (!phone || !message) {
      return NextResponse.json({ error: 'phone e message são obrigatórios' }, { status: 400 });
    }

    const result = await sendWhatsAppMessageFromTenant(tenant.id, phone, message);

    if (!result.ok) {
      return NextResponse.json({ error: result.error ?? 'Falha ao enviar' }, { status: 502 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('[POST whatsapp/send]', error);
    return NextResponse.json({ error: 'Erro ao enviar mensagem' }, { status: 500 });
  }
}
