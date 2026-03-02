/**
 * BarberApp — WhatsApp Bot Handler
 * Máquina de estados para fluxo de agendamento via Meta Cloud API
 * Sessões em DynamoDB (TTL 30min)
 */

import { prisma } from '@/lib/prisma';
import { getBotSession, putBotSession, updateBotSessionState } from '@/lib/dynamodb';

// ============ TYPES ============

export type BotState =
  | 'INICIO'
  | 'AGUARDANDO_SERVICO'
  | 'AGUARDANDO_BARBEIRO'
  | 'AGUARDANDO_DATA'
  | 'AGUARDANDO_SLOT'
  | 'AGUARDANDO_CONFIRMACAO'
  | 'CONCLUIDO';

export interface BotSessionData {
  service_id?: string;
  barber_id?: string | null; // null = qualquer disponível
  date?: string; // YYYY-MM-DD
  slot_id?: string;
  customer_name?: string;
}

export interface BotSession {
  phone: string;
  tenant_id: string;
  state: BotState;
  data: BotSessionData;
  expires_at: Date;
}

// ============ HELPERS ============

function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, '').replace(/^55/, '');
}

function formatDateBR(dateStr: string): string {
  const [y, m, d] = dateStr.split('-');
  return `${d}/${m}/${y}`;
}

function parseUserDate(input: string): string | null {
  const lower = input.toLowerCase().trim();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (lower === 'hoje') {
    return today.toISOString().slice(0, 10);
  }
  if (lower === 'amanha' || lower === 'amanhã') {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().slice(0, 10);
  }

  // Formato DD/MM ou DD/MM/YYYY
  const match = input.match(/^(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?$/);
  if (match) {
    let [, day, month, year] = match;
    if (!year) year = String(today.getFullYear());
    if (year.length === 2) year = '20' + year;
    const d = parseInt(day, 10);
    const m = parseInt(month, 10) - 1;
    const y = parseInt(year, 10);
    const date = new Date(y, m, d);
    if (date >= today) return date.toISOString().slice(0, 10);
  }
  return null;
}

// ============ SEND WHATSAPP ============

async function sendWhatsAppMessage(
  tenantId: string,
  toPhone: string,
  message: string
): Promise<void> {
  const r = await sendWhatsAppMessageFromTenant(tenantId, toPhone, message);
  if (!r.ok) throw new Error(r.error);
}

/** Exportado para uso na API de envio (app admin / mobile). */
export async function sendWhatsAppMessageFromTenant(
  tenantId: string,
  toPhone: string,
  message: string
): Promise<{ ok: boolean; error?: string }> {
  const tenant = await prisma.tenant.findUnique({
    where: { id: tenantId },
    select: { meta_phone_number_id: true, meta_access_token: true },
  });

  if (!tenant?.meta_phone_number_id || !tenant?.meta_access_token) {
    console.error('[BarberBot] Tenant sem WhatsApp configurado:', tenantId);
    return { ok: false, error: 'WhatsApp não configurado' };
  }

  const phoneId = tenant.meta_phone_number_id;
  const token = tenant.meta_access_token;
  const to = normalizePhone(toPhone).includes('55') ? toPhone.replace(/\D/g, '') : '55' + toPhone.replace(/\D/g, '');

  const url = `https://graph.facebook.com/v18.0/${phoneId}/messages`;
  const body = {
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: to.replace(/^55/, ''),
    type: 'text',
    text: { body: message },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error('[BarberBot] Erro ao enviar mensagem:', res.status, err);
    return { ok: false, error: `WhatsApp API: ${res.status}` };
  }
  return { ok: true };
}

// ============ STATE HANDLERS ============

export async function handleIncomingMessage(
  tenantId: string,
  customerPhone: string,
  messageBody: string,
  wamid?: string
): Promise<void> {
  const phone = normalizePhone(customerPhone);
  const text = messageBody.trim();

  let session = await getBotSession(tenantId, phone);
  const tenant = await prisma.tenant.findUnique({
    where: { id: tenantId },
    include: { services: { where: { active: true } }, barbers: { where: { active: true } } },
  });

  if (!tenant) {
    console.error('[BarberBot] Tenant não encontrado:', tenantId);
    return;
  }

  const businessName = tenant.business_name || tenant.name;

  // Comandos especiais (fora do fluxo)
  if (text.toUpperCase() === 'CANCELAR' || text.toUpperCase().startsWith('CANCELAR ')) {
    await handleCancelAppointment(tenantId, phone, text);
    return;
  }

  // Iniciar ou continuar fluxo
  if (!session) {
    session = {
      pk: '',
      sk: 'session',
      tenant_id: tenantId,
      phone,
      state: 'INICIO',
      data: {},
      expires_at: 0,
      updated_at: 0,
    };
    await putBotSession(tenantId, phone, 'INICIO', {});
  }

  const state = session.state as BotState;
  const data = (session.data || {}) as BotSessionData;

  let reply = '';
  let nextState: BotState = state;
  let nextData = { ...data };

  switch (state) {
    case 'INICIO': {
      const choice = text.replace(/\D/g, '');
      if (choice === '1') {
        const services = tenant.services;
        const list = services
          .map((s, i) => `${i + 1}️⃣ ${s.name} R$${s.price}`)
          .join('\n');
        reply = `Ótimo! Qual serviço você quer?\n${list}`;
        nextState = 'AGUARDANDO_SERVICO';
      } else if (choice === '2') {
        await handleListAppointments(tenantId, phone);
        return;
      } else if (choice === '3') {
        reply = 'Para cancelar, digite: CANCELAR [código]\nEx: CANCELAR 123';
      } else if (choice === '4') {
        reply = 'Em breve um atendente responderá. Aguarde!';
      } else {
        reply = `Olá! 👋 Bem-vindo à ${businessName}!\n\nO que você deseja?\n1️⃣ Agendar horário\n2️⃣ Ver meus agendamentos\n3️⃣ Cancelar agendamento\n4️⃣ Falar com atendente`;
      }
      break;
    }

    case 'AGUARDANDO_SERVICO': {
      const idx = parseInt(text.replace(/\D/g, ''), 10);
      const services = tenant.services;
      if (idx >= 1 && idx <= services.length) {
        const service = services[idx - 1];
        nextData.service_id = service.id;
        const barbers = tenant.barbers;
        const list = barbers.map((b, i) => `${i + 1}️⃣ ${b.name}`).join('\n');
        reply = `Com qual barbeiro?\n${list}\n0️⃣ Qualquer disponível`;
        nextState = 'AGUARDANDO_BARBEIRO';
      } else {
        reply = 'Opção inválida. Escolha o número do serviço:\n' + services.map((s, i) => `${i + 1}️⃣ ${s.name}`).join('\n');
      }
      break;
    }

    case 'AGUARDANDO_BARBEIRO': {
      const idx = parseInt(text.replace(/\D/g, ''), 10);
      const barbers = tenant.barbers;
      if (idx === 0) {
        nextData.barber_id = null;
      } else if (idx >= 1 && idx <= barbers.length) {
        nextData.barber_id = barbers[idx - 1].id;
      } else {
        reply = 'Opção inválida. Escolha o número do barbeiro ou 0 para qualquer.';
        break;
      }
      const today = new Date();
      const next3 = [];
      for (let i = 0; i < 3; i++) {
        const d = new Date(today);
        d.setDate(d.getDate() + i);
        next3.push(d.toLocaleDateString('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' }));
      }
      reply = `Qual data? (ex: hoje, amanhã, 15/06)\nOu escolha:\n${next3.map((d, i) => `${i + 1}️⃣ ${d}`).join('\n')}`;
      nextState = 'AGUARDANDO_DATA';
      break;
    }

    case 'AGUARDANDO_DATA': {
      let dateStr: string | null = null;
      const choice = text.replace(/\D/g, '');
      if (choice === '1' || choice === '2' || choice === '3') {
        const today = new Date();
        const idx = parseInt(choice, 10) - 1;
        const d = new Date(today);
        d.setDate(d.getDate() + idx);
        dateStr = d.toISOString().slice(0, 10);
      } else {
        dateStr = parseUserDate(text);
      }
      if (dateStr) {
        nextData.date = dateStr;
        const slots = await getAvailableSlots(tenantId, nextData.barber_id ?? undefined, dateStr);
        if (slots.length === 0) {
          reply = `Não há horários disponíveis em ${formatDateBR(dateStr)}. Escolha outra data.`;
        } else {
          const list = slots.slice(0, 10).map((s, i) => `${i + 1}️⃣ ${s.time}`).join('\n');
          reply = `Horários disponíveis em ${formatDateBR(dateStr)}:\n${list}`;
          nextState = 'AGUARDANDO_SLOT';
        }
      } else {
        reply = 'Data inválida. Use: hoje, amanhã ou DD/MM';
      }
      break;
    }

    case 'AGUARDANDO_SLOT': {
      const slots = await getAvailableSlots(tenantId, nextData.barber_id ?? undefined, nextData.date!);
      const idx = parseInt(text.replace(/\D/g, ''), 10);
      if (idx >= 1 && idx <= slots.length) {
        const slot = slots[idx - 1];
        nextData.slot_id = slot.id;
        const service = tenant.services.find((s) => s.id === nextData.service_id);
        const barber = nextData.barber_id
          ? tenant.barbers.find((b) => b.id === nextData.barber_id)
          : tenant.barbers.find((b) => b.id === slot.barber_id);
        reply = `Confirmado! ✅\n📋 Serviço: ${service?.name ?? '-'}\n💈 Barbeiro: ${barber?.name ?? '-'}\n📅 Data: ${formatDateBR(nextData.date!)}\n⏰ Horário: ${slot.time}\n\nConfirma? (S/N)`;
        nextState = 'AGUARDANDO_CONFIRMACAO';
      } else {
        reply = 'Opção inválida. Escolha o número do horário.';
      }
      break;
    }

    case 'AGUARDANDO_CONFIRMACAO': {
      const confirm = text.toLowerCase();
      if (confirm === 's' || confirm === 'sim') {
        const appointment = await createAppointment(tenantId, phone, nextData);
        reply = `Agendamento confirmado! 🎉\nSeu código: #${appointment.id.slice(0, 8).toUpperCase()}\nTe esperamos! 💈\n\nPara cancelar: CANCELAR ${appointment.id.slice(0, 8).toUpperCase()}`;
        nextState = 'CONCLUIDO';
        nextData = {};
      } else if (confirm === 'n' || confirm === 'nao' || confirm === 'não') {
        reply = 'Agendamento cancelado. Deseja agendar novamente? Digite 1 para sim.';
        nextState = 'INICIO';
        nextData = {};
      } else {
        reply = 'Responda S para confirmar ou N para cancelar.';
      }
      break;
    }

    case 'CONCLUIDO':
      reply = `Olá! 👋 Bem-vindo à ${businessName}!\n\nO que você deseja?\n1️⃣ Agendar horário\n2️⃣ Ver meus agendamentos\n3️⃣ Cancelar agendamento\n4️⃣ Falar com atendente`;
      nextState = 'INICIO';
      break;
  }

  await updateBotSessionState(tenantId, phone, nextState, nextData);
  await sendWhatsAppMessage(tenantId, customerPhone, reply);
}

async function getAvailableSlots(
  tenantId: string,
  barberId: string | undefined | null,
  dateStr: string
): Promise<{ id: string; barber_id: string; time: string }[]> {
  const startOfDay = new Date(dateStr + 'T00:00:00.000Z');
  const endOfDay = new Date(dateStr + 'T23:59:59.999Z');

  const slots = await prisma.slot.findMany({
    where: {
      tenant_id: tenantId,
      status: 'available',
      start_time: { gte: startOfDay, lte: endOfDay },
      ...(barberId ? { barber_id: barberId } : {}),
    },
    orderBy: { start_time: 'asc' },
    select: { id: true, barber_id: true, start_time: true },
  });

  return slots.map((s) => ({
    id: s.id,
    barber_id: s.barber_id,
    time: s.start_time.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
  }));
}

async function createAppointment(
  tenantId: string,
  phone: string,
  data: BotSessionData
): Promise<{ id: string }> {
  const slot = await prisma.slot.findUnique({
    where: { id: data.slot_id! },
    include: { barber: true, tenant: true },
  });

  if (!slot || slot.tenant_id !== tenantId || slot.status !== 'available') {
    throw new Error('Slot indisponível');
  }

  const [datePart] = (data.date ?? '').split('T');
  const [h, m] = slot.start_time.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }).split(':');
  const appointmentDate = new Date(`${datePart}T${h}:${m}:00.000Z`);

  return await prisma.$transaction(async (tx) => {
    const appt = await tx.appointment.create({
      data: {
        tenant_id: tenantId,
        barber_id: slot.barber_id,
        service_id: data.service_id ?? null,
        slot_id: slot.id,
        customer_name: data.customer_name ?? 'Cliente WhatsApp',
        customer_phone: phone,
        appointment_date: appointmentDate,
        status: 'confirmed',
        confirmed: true,
        origin: 'whatsapp',
      },
    });

    await tx.slot.update({
      where: { id: slot.id },
      data: { status: 'booked', appointment_id: appt.id },
    });

    return { id: appt.id };
  });
}

async function handleListAppointments(tenantId: string, customerPhone: string): Promise<void> {
  const appointments = await prisma.appointment.findMany({
    where: {
      tenant_id: tenantId,
      customer_phone: { contains: customerPhone.replace(/\D/g, '') },
      status: { notIn: ['cancelled', 'no_show'] },
      appointment_date: { gte: new Date() },
    },
    include: { barber: true, service: true },
    orderBy: { appointment_date: 'asc' },
    take: 5,
  });

  if (appointments.length === 0) {
    await sendWhatsAppMessage(tenantId, customerPhone, 'Você não tem agendamentos futuros.');
  } else {
    const list = appointments
      .map(
        (a) =>
          `#${a.id.slice(0, 8).toUpperCase()} - ${a.appointment_date.toLocaleDateString('pt-BR')} ${a.appointment_date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })} - ${a.service?.name ?? '-'} - ${a.barber.name}`
      )
      .join('\n');
    await sendWhatsAppMessage(tenantId, customerPhone, `Seus agendamentos:\n${list}`);
  }

  await putBotSession(tenantId, customerPhone, 'INICIO', {});
}

async function handleCancelAppointment(tenantId: string, phone: string, text: string): Promise<void> {
  const code = text.replace(/CANCELAR\s*/i, '').trim().toUpperCase();
  if (!code) {
    await sendWhatsAppMessage(tenantId, phone, 'Use: CANCELAR [código]\nEx: CANCELAR ABC12345');
    return;
  }

  const appointments = await prisma.appointment.findMany({
    where: {
      tenant_id: tenantId,
      customer_phone: { contains: normalizePhone(phone) },
      status: { in: ['pending', 'confirmed'] },
    },
    include: { slot: true },
  });

  const match = appointments.find((a) => a.id.slice(0, 8).toUpperCase() === code);
  if (!match) {
    await sendWhatsAppMessage(tenantId, phone, 'Agendamento não encontrado. Verifique o código.');
    return;
  }

  await prisma.$transaction(async (tx) => {
    await tx.appointment.update({
      where: { id: match.id },
      data: { status: 'cancelled' },
    });
    if (match.slot_id) {
      await tx.slot.update({
        where: { id: match.slot_id },
        data: { status: 'available', appointment_id: null },
      });
    }
  });

  await sendWhatsAppMessage(tenantId, phone, 'Agendamento cancelado com sucesso.');
  await putBotSession(tenantId, phone, 'INICIO', {});
}

/**
 * Mensagem inicial ao receber primeira interação
 */
export async function sendWelcomeMessage(tenantId: string, customerPhone: string): Promise<void> {
  const tenant = await prisma.tenant.findUnique({
    where: { id: tenantId },
    select: { business_name: true, name: true },
  });
  const businessName = tenant?.business_name || tenant?.name || 'Barbearia';
  const msg = `Olá! 👋 Bem-vindo à ${businessName}!\n\nO que você deseja?\n1️⃣ Agendar horário\n2️⃣ Ver meus agendamentos\n3️⃣ Cancelar agendamento\n4️⃣ Falar com atendente`;
  await putBotSession(tenantId, normalizePhone(customerPhone), 'INICIO', {});
  await sendWhatsAppMessage(tenantId, customerPhone, msg);
}
