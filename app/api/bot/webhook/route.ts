/**
 * WhatsApp Meta Cloud API Webhook
 * GET: Verificação (Meta envia hub.mode, hub.verify_token, hub.challenge)
 * POST: Eventos (mensagens recebidas)
 */

import { NextRequest, NextResponse } from 'next/server';
import { handleIncomingMessage } from '@/lib/whatsapp-bot/barber-bot-handler';
import { prisma } from '@/lib/prisma';
import { saveBotMessage } from '@/lib/whatsapp-bot/save-bot-message';

const META_VERIFY_TOKEN = process.env.META_VERIFY_TOKEN || 'barberapp-verify-2025';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const mode = searchParams.get('hub.mode');
  const token = searchParams.get('hub.verify_token');
  const challenge = searchParams.get('hub.challenge');

  if (mode !== 'subscribe' || token !== META_VERIFY_TOKEN) {
    return NextResponse.json({ error: 'Invalid verify token or mode' }, { status: 403 });
  }
  if (challenge == null || challenge === '') {
    return NextResponse.json({ error: 'Missing hub.challenge' }, { status: 400 });
  }

  return new NextResponse(challenge, {
    status: 200,
    headers: { 'Content-Type': 'text/plain' },
  });
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    if (body.object !== 'whatsapp_business_account') {
      return NextResponse.json({ error: 'Invalid object' }, { status: 400 });
    }

    const entries = body.entry || [];
    for (const entry of entries) {
      const changes = entry.changes || [];
      for (const change of changes) {
        if (change.field !== 'messages') continue;
        const value = change.value;

        const messages = value.messages || [];
        const metadata = value.metadata || {};
        const phoneNumberId = metadata.phone_number_id != null ? String(metadata.phone_number_id) : undefined;

        console.log('[Webhook] POST recebido — phone_number_id:', phoneNumberId, 'mensagens:', messages?.length);

        const tenant = await prisma.tenant.findFirst({
          where: { meta_phone_number_id: phoneNumberId },
        });

        if (!tenant) {
          console.warn('[Webhook] Tenant não encontrado para phone_number_id:', phoneNumberId, '— Confira se o tenant no banco tem meta_phone_number_id =', phoneNumberId);
          continue;
        }

        for (const msg of messages) {
          if (msg.type !== 'text') {
            console.log('[Webhook] Mensagem ignorada (tipo não é text):', msg.type);
            continue;
          }
          const from = msg.from;
          const text = msg.text?.body || '';
          const wamid = msg.id;

          const customerPhone = '55' + String(from);
          console.log('[Webhook] Processando — tenant:', tenant.id, 'from:', customerPhone, 'text:', text?.slice(0, 50));

          try {
            await saveBotMessage(tenant.id, customerPhone, 'in', text, wamid);
            await handleIncomingMessage(tenant.id, customerPhone, text, wamid);
          } catch (err) {
            console.error('[Webhook] Erro ao processar mensagem:', err);
          }
        }
      }
    }

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (error) {
    console.error('[Webhook] Erro:', error);
    return NextResponse.json({ error: 'Webhook processing failed' }, { status: 500 });
  }
}
