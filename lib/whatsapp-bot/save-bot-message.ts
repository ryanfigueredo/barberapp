/**
 * Persiste mensagens do bot no PostgreSQL (BotMessage) para o inbox do dashboard.
 */

import { prisma } from '@/lib/prisma';

export async function saveBotMessage(
  tenantId: string,
  customerPhone: string,
  direction: 'in' | 'out',
  body: string,
  wamid?: string | null
): Promise<void> {
  const phone = customerPhone.replace(/\D/g, '').replace(/^55/, '') || customerPhone;
  try {
    await prisma.botMessage.create({
      data: {
        tenant_id: tenantId,
        customer_phone: phone,
        direction,
        body,
        wamid: wamid || null,
        is_bot: direction === 'out',
      },
    });
  } catch (e) {
    if ((e as { code?: string }).code === 'P2002') return; // unique wamid, skip
    console.error('[saveBotMessage]', e);
  }
}
