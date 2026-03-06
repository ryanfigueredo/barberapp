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
  console.log('[Webhook] ========== POST recebido', new Date().toISOString(), '==========');
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
        // Meta envia phone_number_id do número que recebeu a mensagem (ex: 983471751512371).
        // Não confundir com o ID da conta WhatsApp Business (WABA), que é outro.
        const phoneNumberId = metadata.phone_number_id != null ? String(metadata.phone_number_id) : undefined;

        console.log('[Webhook] POST recebido — phone_number_id:', phoneNumberId, 'mensagens:', messages?.length, 'metadata:', JSON.stringify(metadata));

        if (!phoneNumberId) {
          console.warn('[Webhook] phone_number_id ausente no metadata, ignorando change.');
          continue;
        }

        const connectionRow = await prisma.tenantWhatsApp.findUnique({
          where: { meta_phone_number_id: phoneNumberId },
          include: { tenant: true },
        });

        type WebhookConnection = { tenant: { id: string; slug: string; name: string }; barber_id: string | null };
        let resolved: WebhookConnection | null = connectionRow
          ? { tenant: connectionRow.tenant, barber_id: connectionRow.barber_id }
          : null;

        if (!resolved && phoneNumberId) {
          const legacyTenant = await prisma.tenant.findFirst({
            where: { meta_phone_number_id: phoneNumberId },
          });
          if (legacyTenant) {
            console.log('[Webhook] Usando Tenant legado (meta_phone_number_id no Tenant):', legacyTenant.id);
            resolved = {
              tenant: { id: legacyTenant.id, slug: legacyTenant.slug, name: legacyTenant.name },
              barber_id: null,
            };
          }
        }

        if (!resolved) {
          console.warn('[Webhook] Conexão não encontrada para phone_number_id:', phoneNumberId, '— Verifique Tenant ou TenantWhatsApp no banco.');
          continue;
        }

        const tenant = resolved.tenant;
        const defaultBarberId = resolved.barber_id ?? undefined;

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
