/**
 * Webhook Meta (WhatsApp) — URL alternativa para configuração no Meta Developers.
 * GET: Verificação (hub.mode, hub.verify_token, hub.challenge)
 * POST: Eventos WhatsApp
 *
 * Use esta URL no Meta: https://seu-dominio.vercel.app/api/webhook/meta
 */

import { NextRequest } from 'next/server';
import { GET as botGet, POST as botPost } from '@/app/api/bot/webhook/route';

export async function GET(request: NextRequest) {
  return botGet(request);
}

export async function POST(request: NextRequest) {
  return botPost(request);
}
