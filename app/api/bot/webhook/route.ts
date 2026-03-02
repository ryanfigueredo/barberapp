/**
 * WhatsApp Meta Cloud API Webhook
 * GET: Verificação (Meta envia hub.mode, hub.verify_token, hub.challenge)
 * POST: Eventos (mensagens recebidas)
 */

import { NextRequest, NextResponse } from 'next/server';
import { handleIncomingMessage } from '@/lib/whatsapp-bot/barber-bot-handler';
import { prisma } from '@/lib/prisma';

const META_VERIFY_TOKEN = process.env.META_VERIFY_TOKEN || 'barberapp-verify-2025';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const mode = searchParams.get('hub.mode');
  const token = searchParams.get('hub.verify_token');
  const challenge = searchParams.get('hub.challenge');

  if (mode === 'subscribe' && token === META_VERIFY_TOKEN) {
    return new NextResponse(challenge, { status: 200 });
  }
  return NextResponse.json({ error: 'Invalid verify token' }, { status: 403 });
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
        const phoneNumberId = metadata.phone_number_id;

        // Buscar tenant pelo phone_number_id
        const tenant = await prisma.tenant.findFirst({
          where: { meta_phone_number_id: phoneNumberId },
        });

        if (!tenant) {
          console.warn('[Webhook] Tenant não encontrado para phone_number_id:', phoneNumberId);
          continue;
        }

        for (const msg of messages) {
          if (msg.type !== 'text') continue;
          const from = msg.from;
          const text = msg.text?.body || '';
          const wamid = msg.id;

          const customerPhone = '55' + String(from);

          try {
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
