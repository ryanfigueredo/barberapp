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

    console.log('[Webhook] POST body keys:', Object.keys(body), 'object:', body.object);

    if (body.object !== 'whatsapp_business_account') {
      return NextResponse.json({ error: 'Invalid object' }, { status: 400 });
    }

    const entries = body.entry || [];
    if (entries.length === 0) {
      console.log('[Webhook] POST sem entries (status/reaction?):', JSON.stringify(body).slice(0, 300));
    }
    for (const entry of entries) {
      const changes = entry.changes || [];
      for (const change of changes) {
        if (change.field !== 'messages') {
          console.log('[Webhook] change.field ignorado:', change.field);
          continue;
        }
        const value = change.value;

        const messages = value.messages || [];
        const metadata = value.metadata || {};
        const phoneNumberId = metadata.phone_number_id != null ? String(metadata.phone_number_id) : undefined;

        console.log('[Webhook] POST recebido — phone_number_id:', phoneNumberId, 'mensagens:', messages?.length, 'metadata:', JSON.stringify(metadata));

        let connection = await prisma.tenantWhatsApp.findUnique({
          where: { meta_phone_number_id: phoneNumberId },
          include: { tenant: true },
        });

        if (!connection?.tenant && phoneNumberId) {
          const legacyTenant = await prisma.tenant.findFirst({
            where: { meta_phone_number_id: phoneNumberId },
          });
          if (legacyTenant) {
            console.log('[Webhook] Usando Tenant legado (meta_phone_number_id no Tenant):', legacyTenant.id);
            connection = {
              id: '',
              tenant_id: legacyTenant.id,
              barber_id: null,
              tenant: { id: legacyTenant.id, slug: legacyTenant.slug, name: legacyTenant.name },
            } as { id: string; tenant_id: string; barber_id: string | null; tenant: { id: string; slug: string; name: string } };
          }
        }

        if (!connection?.tenant) {
          console.warn('[Webhook] Conexão não encontrada para phone_number_id:', phoneNumberId, '— Verifique Tenant ou TenantWhatsApp no banco.');
          continue;
        }

        const tenant = connection.tenant;
        const defaultBarberId = connection.barber_id ?? undefined;

        for (const msg of messages) {
          if (msg.type !== 'text') {
            console.log('[Webhook] Mensagem ignorada (tipo não é text):', msg.type);
            continue;
          }
          const from = msg.from;
          const text = msg.text?.body || '';
          const wamid = msg.id;

          const customerPhone = '55' + String(from);
          console.log('[Webhook] Processando — tenant:', tenant.id, 'barber_id:', defaultBarberId, 'from:', customerPhone, 'text:', text?.slice(0, 50));

          try {
            await saveBotMessage(tenant.id, customerPhone, 'in', text, wamid);
            await handleIncomingMessage(tenant.id, customerPhone, text, wamid, defaultBarberId);
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
