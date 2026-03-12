/**
 * BarberApp — WhatsApp Bot Handler
 * Máquina de estados para fluxo de agendamento via Meta Cloud API
 * Sessões em DynamoDB (TTL 30 min, last_activity_at para timeout 20 min)
 */

import { prisma } from '@/lib/prisma';
import { getBotSession, putBotSession, updateBotSessionState, type BotSessionRecord } from '@/lib/dynamodb';
import { saveBotMessage } from '@/lib/whatsapp-bot/save-bot-message';

// ============ CONSTANTS ============

const SESSION_INACTIVITY_MS = 20 * 60 * 1000; // 20 min

const TIMEZONE_BRAZIL = 'America/Sao_Paulo';

/** Retorna hoje no fuso America/Sao_Paulo no formato YYYY-MM-DD */
function getTodayBrazil(): string {
  return new Date().toLocaleDateString('en-CA', { timeZone: TIMEZONE_BRAZIL });
}

/** Soma dias a uma data YYYY-MM-DD e retorna YYYY-MM-DD (em Brasil). */
function addDaysBrazil(dateStr: string, days: number): string {
  const [y, m, d] = dateStr.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d + days));
  return date.toISOString().slice(0, 10);
}

// ============ TYPES ============

export type BotState =
  | 'INICIO'
  | 'AGUARDANDO_NOME'
  | 'AGUARDANDO_SERVICO'
  | 'AGUARDANDO_BARBEIRO'
  | 'AGUARDANDO_DATA'
  | 'AGUARDANDO_SLOT'
  | 'AGUARDANDO_CONFIRMACAO'
  | 'AGUARDANDO_CONFIRMACAO_ATENDENTE'
  | 'AGUARDANDO_REAGENDAMENTO'
  | 'AGUARDANDO_RECOMECAR'
  | 'CONCLUIDO';

export interface BotSessionData {
  service_id?: string;
  barber_id?: string | null;
  date?: string;
  slot_id?: string;
  customer_name?: string;
  rescheduling_appointment_id?: string;
  last_activity_at?: number;
  expired_awaiting_reconfirm?: boolean;
  connection_barber_id?: string | null;
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

function formatDateLongBR(dateStr: string, timeStr: string): string {
  const d = new Date(dateStr + 'T12:00:00.000Z');
  const weekday = d.toLocaleDateString('pt-BR', { weekday: 'long' });
  const dayMonth = formatDateBR(dateStr);
  return `${weekday.charAt(0).toUpperCase() + weekday.slice(1)}, ${dayMonth} às ${timeStr}`;
}

/** Aceita: hoje, amanhã, DD/MM, DD/MM/YYYY — datas em America/Sao_Paulo */
function parseUserDate(input: string): string | null {
  const lower = input.toLowerCase().trim();
  const todayStr = getTodayBrazil();
  const [ty] = todayStr.split('-').map(Number);

  if (lower === 'hoje') return todayStr;
  if (lower === 'amanha' || lower === 'amanhã') return addDaysBrazil(todayStr, 1);

  const match = input.match(/^(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?$/);
  if (match) {
    let [, day, month, year] = match;
    const d = parseInt(String(day), 10);
    const m = parseInt(String(month), 10);
    let y = parseInt(String(year || ty), 10);
    if (year && String(year).length === 2) y = 2000 + (y % 100);
    const dateStr = `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    if (dateStr >= todayStr) return dateStr;
  }
  return null;
}

/** Extrai hora do texto: "17h", "17:00", "9h" → { hour, minute } ou null */
function parseTimeInText(text: string): { hour: number; minute: number } | null {
  const t = text.toLowerCase().trim();
  const match = t.match(/(\d{1,2})h(?:\s*(\d{2}))?|(\d{1,2}):(\d{2})/);
  if (match) {
    const hour = parseInt(match[1] ?? match[3] ?? '0', 10);
    const minute = parseInt(match[2] ?? match[4] ?? '0', 10);
    if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) return { hour, minute };
  }
  return null;
}

/** Tenta extrair data do texto (hoje, amanhã, DD/MM). Retorna o que sobrou sem a parte da data. */
function extractDateFromText(text: string): { dateStr: string; rest: string } | null {
  const lower = text.toLowerCase().trim();
  const todayStr = getTodayBrazil();
  if (lower.includes('amanhã') || lower.includes('amanha')) {
    const rest = lower.replace(/\b(amanhã|amanha)\b/g, '').replace(/\s+/g, ' ').trim();
    return { dateStr: addDaysBrazil(todayStr, 1), rest };
  }
  if (lower.includes('hoje')) {
    const rest = lower.replace(/\bhoje\b/g, '').replace(/\s+/g, ' ').trim();
    return { dateStr: todayStr, rest };
  }
  const dateMatch = text.match(/\b(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?\b/);
  if (dateMatch) {
    const [full] = dateMatch;
    const dateStr = parseUserDate(full);
    if (dateStr) {
      const rest = text.replace(full, '').replace(/\s+/g, ' ').trim();
      return { dateStr, rest };
    }
  }
  return null;
}

/** Encontra serviço por nome aproximado (ex: "cabelo e barba" → "Corte + Barba"). */
function matchServiceName(text: string, services: { id: string; name: string }[]): { id: string; name: string } | null {
  const lower = text.toLowerCase().replace(/\s*[+]\s*/g, ' ').replace(/\s+e\s+/g, ' ').trim();
  const words = lower.split(/\s+/).filter(Boolean);
  if (words.length === 0) return null;
  for (const s of services) {
    const nameLower = s.name.toLowerCase().replace(/\s*[+]\s*/g, ' ').replace(/\s+e\s+/g, ' ');
    const hasCorteCabelo = words.some((w) => /^(corte|cabelo)$/.test(w)) || nameLower.includes('corte') || nameLower.includes('cabelo');
    const hasBarba = words.some((w) => /barba/.test(w)) || nameLower.includes('barba');
    const allMatch = words.every((w) => nameLower.includes(w) || (w === 'cabelo' && nameLower.includes('corte')));
    if (allMatch || (hasBarba && hasCorteCabelo)) return s;
  }
  return null;
}

/** Parse "cabelo e barba amanhã 17h". Retorna null se não extrair serviço + data + hora. */
function parseQuickBook(
  text: string,
  services: { id: string; name: string }[],
  _todayStr: string
): { service_id: string; dateStr: string; hour: number; minute: number } | null {
  const trimmed = text.trim();
  if (trimmed.length < 5 || /^[0-6]\s*$/.test(trimmed)) return null;
  let rest = trimmed;
  let dateStr: string | null = null;
  const dateExtract = extractDateFromText(rest);
  if (dateExtract) {
    dateStr = dateExtract.dateStr;
    rest = dateExtract.rest;
  }
  const timeMatch = parseTimeInText(rest);
  if (!timeMatch) return null;
  rest = rest.replace(/\d{1,2}h(?:\s*\d{2})?/i, '').replace(/\d{1,2}:\d{2}/, '').replace(/\s+/g, ' ').trim();
  const service = matchServiceName(rest || 'corte', services);
  if (!service || !dateStr) return null;
  return { service_id: service.id, dateStr, hour: timeMatch.hour, minute: timeMatch.minute };
}

function isGlobalBack(text: string): boolean {
  const t = text.toLowerCase().trim();
  return t === 'voltar' || t === 'menu' || t === '0';
}

function isRemarcar(text: string): boolean {
  return text.toLowerCase().trim() === 'remarcar';
}

function isAjuda(text: string): boolean {
  const t = text.toLowerCase().trim();
  return t === 'ajuda' || t === '?';
}

function isConfirmYes(text: string): boolean {
  const t = text.toLowerCase().trim();
  return ['s', 'sim', 'yes', '1'].includes(t);
}

function isConfirmNo(text: string): boolean {
  const t = text.toLowerCase().trim();
  return ['n', 'nao', 'não', 'no', '2'].includes(t);
}

/** Detecta se o cliente quer falar com atendente (opção 5 ou frases como "atendente", "falar com alguém") */
function wantsAttendant(text: string): boolean {
  const t = text.toLowerCase().trim();
  if (t === '5') return true;
  if (/atendente/.test(t)) return true;
  if (/falar\s+com\s+(um\s+)?atendente/.test(t)) return true;
  if (/falar\s+com\s+algu[eé]m/.test(t)) return true;
  if (/quero\s+falar\s+com/.test(t)) return true;
  if (/preciso\s+falar\s+com/.test(t)) return true;
  if (/falar\s+com\s+humano/.test(t)) return true;
  return false;
}

function getMenuMessage(businessName: string, customerName?: string | null): string {
  const greeting = customerName ? `Olá, ${customerName}! ✂️` : `Olá! 👋 Bem-vindo à ${businessName}!`;
  return `${greeting}\n\nO que você deseja?\n1️⃣ Agendar horário\n2️⃣ Ver meus agendamentos\n3️⃣ Cancelar agendamento\n4️⃣ Remarcar agendamento\n5️⃣ Falar com atendente\n6️⃣ Alterar meu nome`;
}

function getMenuListPayload(businessName: string, customerName?: string | null): InteractiveListPayload {
  const greeting = customerName ? `Olá, ${customerName}! ✂️` : `Olá! 👋 Bem-vindo à ${businessName}!`;
  return {
    body: `${greeting}\n\nSelecione abaixo a opção que deseja:`,
    button: 'Exibir opções',
    sections: [
      {
        rows: [
          { id: '1', title: 'Agendar horário' },
          { id: '2', title: 'Ver meus agendamentos' },
          { id: '3', title: 'Cancelar agendamento' },
          { id: '4', title: 'Remarcar agendamento' },
          { id: '5', title: 'Falar com atendente' },
          { id: '6', title: 'Alterar meu nome' },
        ],
      },
    ],
  };
}

function getHelpMessage(): string {
  return `📋 *Comandos disponíveis:*\n\n• *voltar* ou *menu* ou *0* — Voltar ao menu\n• *remarcar* — Iniciar remarcação mantendo serviço\n• *6* — Alterar meu nome\n• *ajuda* ou *?* — Ver esta mensagem\n• *CANCELAR #código* — Cancelar um agendamento (ex: CANCELAR A3F8K2)`;
}

/** Nome definido no painel (renomear cliente). Retorna null se tabela não existir (P2021). */
async function getContactDisplayName(tenantId: string, phone: string): Promise<string | null> {
  try {
    const phoneForDb = phone.startsWith('55') ? phone : '55' + phone;
    const row = await prisma.whatsAppContactName.findUnique({
      where: { tenant_id_customer_phone: { tenant_id: tenantId, customer_phone: phoneForDb } },
      select: { display_name: true },
    });
    return row?.display_name ?? null;
  } catch (e: unknown) {
    if (e && typeof e === 'object' && 'code' in e && e.code === 'P2021') return null; // tabela não existe
    throw e;
  }
}

// ============ SEND WHATSAPP ============

async function sendWhatsAppMessage(
  tenantId: string,
  toPhone: string,
  message: string,
  connectionBarberId?: string | null
): Promise<void> {
  const r = await sendWhatsAppMessageFromTenant(tenantId, toPhone, message, connectionBarberId);
  if (!r.ok) {
    if (r.error === 'WhatsApp não configurado') {
      console.warn('[BarberBot] Resposta não enviada (WhatsApp não configurado no tenant).');
      return;
    }
    throw new Error(r.error);
  }
}

async function sendAndLog(
  tenantId: string,
  toPhone: string,
  message: string,
  connectionBarberId?: string | null
): Promise<void> {
  await sendWhatsAppMessage(tenantId, toPhone, message, connectionBarberId);
  const phone = normalizePhone(toPhone);
  await saveBotMessage(tenantId, phone ? '55' + phone : toPhone, 'out', message);
}

export interface InteractiveListPayload {
  body: string;
  button: string;
  sections: { title?: string; rows: { id: string; title: string }[] }[];
}

async function sendWhatsAppInteractiveList(
  tenantId: string,
  toPhone: string,
  payload: InteractiveListPayload,
  connectionBarberId?: string | null
): Promise<{ ok: boolean; error?: string }> {
  const where: { tenant_id: string; barber_id?: string | null } = { tenant_id: tenantId };
  if (connectionBarberId != null && connectionBarberId !== '') {
    where.barber_id = connectionBarberId;
  } else {
    where.barber_id = null;
  }
  let connection = await prisma.tenantWhatsApp.findFirst({
    where,
    select: { meta_phone_number_id: true, meta_access_token: true },
  });
  if (!connection && (connectionBarberId == null || connectionBarberId === '')) {
    connection = await prisma.tenantWhatsApp.findFirst({
      where: { tenant_id: tenantId },
      select: { meta_phone_number_id: true, meta_access_token: true },
    });
  }
  if (!connection?.meta_phone_number_id || !connection?.meta_access_token) {
    const legacyTenant = await prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { meta_phone_number_id: true, meta_access_token: true },
    });
    if (legacyTenant?.meta_phone_number_id && legacyTenant?.meta_access_token) {
      connection = {
        meta_phone_number_id: legacyTenant.meta_phone_number_id,
        meta_access_token: legacyTenant.meta_access_token,
      };
    }
  }
  if (!connection?.meta_phone_number_id || !connection?.meta_access_token) {
    return { ok: false, error: 'WhatsApp não configurado' };
  }
  const phoneId = connection.meta_phone_number_id;
  const token = connection.meta_access_token;
  const to = normalizePhone(toPhone).includes('55') ? toPhone.replace(/\D/g, '') : '55' + toPhone.replace(/\D/g, '');

  const body = {
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: to.replace(/^55/, ''),
    type: 'interactive',
    interactive: {
      type: 'list',
      body: { text: payload.body },
      action: {
        button: payload.button,
        sections: payload.sections.map((sec) => ({
          title: sec.title || '',
          rows: sec.rows.slice(0, 10).map((r) => ({ id: r.id, title: r.title })),
        })),
      },
    },
  };

  const res = await fetch(`https://graph.facebook.com/v18.0/${phoneId}/messages`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error('[BarberBot] Erro ao enviar lista interativa:', res.status, err);
    return { ok: false, error: `WhatsApp API: ${res.status}` };
  }
  return { ok: true };
}

async function sendAndLogInteractive(
  tenantId: string,
  toPhone: string,
  payload: InteractiveListPayload,
  logSummary: string,
  connectionBarberId?: string | null
): Promise<void> {
  const r = await sendWhatsAppInteractiveList(tenantId, toPhone, payload, connectionBarberId);
  if (!r.ok && r.error !== 'WhatsApp não configurado') throw new Error(r.error);
  const phone = normalizePhone(toPhone);
  await saveBotMessage(tenantId, phone ? '55' + phone : toPhone, 'out', logSummary);
}

export async function sendWhatsAppMessageFromTenant(
  tenantId: string,
  toPhone: string,
  message: string,
  connectionBarberId?: string | null
): Promise<{ ok: boolean; error?: string }> {
  const where: { tenant_id: string; barber_id?: string | null } = { tenant_id: tenantId };
  if (connectionBarberId != null && connectionBarberId !== '') {
    where.barber_id = connectionBarberId;
  } else {
    where.barber_id = null;
  }

  let connection = await prisma.tenantWhatsApp.findFirst({
    where,
    select: { meta_phone_number_id: true, meta_access_token: true },
  });

  if (!connection && (connectionBarberId == null || connectionBarberId === '')) {
    connection = await prisma.tenantWhatsApp.findFirst({
      where: { tenant_id: tenantId },
      select: { meta_phone_number_id: true, meta_access_token: true },
    });
  }

  if (!connection?.meta_phone_number_id || !connection?.meta_access_token) {
    const legacyTenant = await prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { meta_phone_number_id: true, meta_access_token: true },
    });
    if (legacyTenant?.meta_phone_number_id && legacyTenant?.meta_access_token) {
      connection = {
        meta_phone_number_id: legacyTenant.meta_phone_number_id,
        meta_access_token: legacyTenant.meta_access_token,
      };
    }
  }

  if (!connection?.meta_phone_number_id || !connection?.meta_access_token) {
    return { ok: false, error: 'WhatsApp não configurado' };
  }

  const phoneId = connection.meta_phone_number_id;
  const token = connection.meta_access_token;
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
    console.error('[BarberBot] Erro ao enviar:', res.status, err);
    if (res.status === 401) {
      console.warn(
        '[BarberBot] 401 = token inválido ou expirado. Atualize meta_access_token em TenantWhatsApp (ou Tenant) com o token do Meta → WhatsApp → Configuração da API.'
      );
    }
    return { ok: false, error: `WhatsApp API: ${res.status}` };
  }
  return { ok: true };
}

// ============ SLOTS & APPOINTMENTS (unchanged signatures, only called) ============

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

/** Encontra slot(s) disponível na data e hora (ex: 17:00). */
async function getSlotsAtTime(
  tenantId: string,
  dateStr: string,
  hour: number,
  minute: number,
  barberId?: string | null
): Promise<{ id: string; barber_id: string; time: string }[]> {
  const slots = await getAvailableSlots(tenantId, barberId ?? undefined, dateStr);
  const target = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  return slots.filter((s) => s.time === target);
}

/** Retorna até 3 próximas datas (YYYY-MM-DD) que tenham pelo menos um slot. */
async function getNextDatesWithSlots(
  tenantId: string,
  barberId: string | undefined | null,
  fromDateStr: string,
  limit = 3
): Promise<string[]> {
  const result: string[] = [];
  const fromDate = new Date(fromDateStr + 'T12:00:00.000Z');
  let d = new Date(fromDate);
  const todayStr = getTodayBrazil();
  const today = new Date(todayStr + 'T12:00:00.000Z');
  if (d < today) d = today;
  for (let i = 0; i < 14 && result.length < limit; i++) {
    const dateStr = d.toISOString().slice(0, 10);
    const slots = await getAvailableSlots(tenantId, barberId, dateStr);
    if (slots.length > 0) result.push(dateStr);
    d.setUTCDate(d.getUTCDate() + 1);
  }
  return result;
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

/** Registra pedido de atendente para o painel priorizar a conversa. */
async function createAttendantRequest(
  tenantId: string,
  customerPhone: string,
  customerName?: string | null
): Promise<void> {
  try {
    const phoneNorm = customerPhone.replace(/\D/g, '');
    const phoneForDb = phoneNorm.startsWith('55') ? phoneNorm : '55' + phoneNorm;
    await prisma.whatsAppAttendantRequest.create({
      data: {
        tenant_id: tenantId,
        customer_phone: phoneForDb,
        customer_name: customerName || null,
      },
    });
  } catch (e) {
    if ((e as { code?: string }).code === 'P2021') return; // tabela não existe ainda
    console.error('[BarberBot] createAttendantRequest', e);
  }
}

/** Cancela um agendamento e libera o slot (uso interno, ex.: remarcar). */
async function cancelAppointmentById(tenantId: string, appointmentId: string): Promise<void> {
  const appt = await prisma.appointment.findFirst({
    where: { id: appointmentId, tenant_id: tenantId, status: { in: ['pending', 'confirmed'] } },
    include: { slot: true },
  });
  if (!appt) return;
  await prisma.$transaction(async (tx) => {
    await tx.appointment.update({
      where: { id: appt.id },
      data: { status: 'cancelled' },
    });
    if (appt.slot_id) {
      await tx.slot.update({
        where: { id: appt.slot_id },
        data: { status: 'available', appointment_id: null },
      });
    }
  });
}

async function handleListAppointments(tenantId: string, customerPhone: string, connectionBarberId?: string | null): Promise<void> {
  const phoneNorm = normalizePhone(customerPhone);
  const appointments = await prisma.appointment.findMany({
    where: {
      tenant_id: tenantId,
      customer_phone: { contains: phoneNorm },
      status: { notIn: ['cancelled', 'no_show'] },
      appointment_date: { gte: new Date() },
    },
    include: { barber: true, service: true },
    orderBy: { appointment_date: 'asc' },
    take: 5,
  });

  if (appointments.length === 0) {
    await sendAndLog(tenantId, customerPhone, 'Você não tem agendamentos futuros. 📅', connectionBarberId);
  } else {
    const list = appointments
      .map(
        (a) =>
          `#${a.id.slice(0, 8).toUpperCase()} - ${a.appointment_date.toLocaleDateString('pt-BR')} ${a.appointment_date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })} - ${a.service?.name ?? '-'} - ${a.barber.name}`
      )
      .join('\n');
    await sendAndLog(tenantId, customerPhone, `📋 *Seus agendamentos:*\n${list}`, connectionBarberId);
  }

  await putBotSession(tenantId, customerPhone, 'INICIO', { connection_barber_id: connectionBarberId ?? undefined });
}

async function handleCancelAppointment(
  tenantId: string,
  phone: string,
  text: string,
  connectionBarberId?: string | null
): Promise<void> {
  const code = text.replace(/CANCELAR\s*/i, '').trim().toUpperCase();
  if (!code) {
    await sendAndLog(tenantId, phone, 'Use: CANCELAR #código\nEx: CANCELAR A3F8K2', connectionBarberId);
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
    await sendAndLog(tenantId, phone, 'Agendamento não encontrado. Verifique o código e tente novamente.', connectionBarberId);
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

  await sendAndLog(tenantId, phone, '✅ Agendamento cancelado com sucesso.', connectionBarberId);
  await putBotSession(tenantId, phone, 'INICIO', { connection_barber_id: connectionBarberId ?? undefined });
}

// ============ MAIN HANDLER ============

export async function handleIncomingMessage(
  tenantId: string,
  customerPhone: string,
  messageBody: string,
  _wamid?: string,
  defaultBarberId?: string | null
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
  const connectionBarberId = (session?.data as BotSessionData)?.connection_barber_id ?? defaultBarberId ?? null;

  // Nome definido no painel (renomear) sobrescreve o da sessão — ignora se tabela ainda não existir (P2021)
  if (session) {
    const contactName = await getContactDisplayName(tenantId, phone);
    if (contactName) {
      session = {
        ...session,
        data: { ...(session.data || {}), customer_name: contactName } as BotSessionRecord['data'],
      } as BotSessionRecord;
    }
  }

  // ----- Comando global: CANCELAR -----
  if (text.toUpperCase() === 'CANCELAR' || text.toUpperCase().startsWith('CANCELAR ')) {
    await handleCancelAppointment(tenantId, customerPhone, text, connectionBarberId);
    return;
  }

  // ----- Sessão expirada (20 min)? -----
  const sessionRecord = session as { updated_at?: number; data?: BotSessionData } | null;
  const rawLast =
    (session?.data as BotSessionData | undefined)?.last_activity_at ??
    (sessionRecord?.updated_at ? sessionRecord.updated_at * 1000 : 0);
  const lastActivity: number = typeof rawLast === 'number' ? rawLast : 0;
  if (session && Date.now() - lastActivity > SESSION_INACTIVITY_MS) {
    const reply = 'Olá! Sua sessão anterior expirou. Quer recomeçar? (S/N)';
    await putBotSession(tenantId, phone, 'INICIO', {
      expired_awaiting_reconfirm: true,
      last_activity_at: Date.now(),
      customer_name: (session.data as BotSessionData)?.customer_name,
      connection_barber_id: connectionBarberId ?? undefined,
    });
    await sendAndLog(tenantId, customerPhone, reply, connectionBarberId);
    return;
  }

  // ----- Comandos globais (em qualquer estado) -----
  if (isAjuda(text)) {
    await sendAndLog(tenantId, customerPhone, getHelpMessage(), connectionBarberId);
    const data = (session?.data ?? {}) as BotSessionData;
    await updateBotSessionState(tenantId, phone, session?.state ?? 'INICIO', {
      ...data,
      last_activity_at: Date.now(),
    });
    return;
  }

  if (isGlobalBack(text)) {
    const data = (session?.data ?? {}) as BotSessionData;
    const keepData: BotSessionData = { customer_name: data.customer_name, last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? undefined };
    await putBotSession(tenantId, phone, 'INICIO', keepData as Record<string, unknown>);
    await sendAndLogInteractive(tenantId, customerPhone, getMenuListPayload(businessName, keepData.customer_name), getMenuMessage(businessName, keepData.customer_name), connectionBarberId);
    return;
  }

  /** Em qualquer estado: "5" ou "Falar com atendente" / "atendente" → pergunta se deseja e depois envia para atendente */
  if (wantsAttendant(text)) {
    const data = (session?.data ?? {}) as BotSessionData;
    const keepData: BotSessionData = { customer_name: data.customer_name, last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? undefined };
    await putBotSession(tenantId, phone, 'AGUARDANDO_CONFIRMACAO_ATENDENTE', keepData as Record<string, unknown>);
    await sendAndLog(
      tenantId,
      customerPhone,
      'Deseja falar com um atendente? Responda *S* para sim ou *N* para voltar ao menu.',
      connectionBarberId
    );
    return;
  }

  if (isRemarcar(text)) {
    const data = (session?.data ?? {}) as BotSessionData;
    const nextData: BotSessionData = {
      customer_name: data.customer_name,
      service_id: data.service_id,
      last_activity_at: Date.now(),
      connection_barber_id: connectionBarberId ?? undefined,
    };
    if (data.service_id) {
      const barbers = tenant.barbers;
      const list = barbers.map((b, i) => `${i + 1}️⃣ ${b.name}`).join('\n');
      await putBotSession(tenantId, phone, 'AGUARDANDO_BARBEIRO', nextData as Record<string, unknown>);
      await sendAndLog(tenantId, customerPhone, `✂️ Remarcar — Com qual barbeiro?\n${list}\n0️⃣ Qualquer disponível`, connectionBarberId);
    } else {
      const list = tenant.services.map((s, i) => `${i + 1}️⃣ ${s.name} — R$ ${s.price}`).join('\n');
      await putBotSession(tenantId, phone, 'AGUARDANDO_SERVICO', nextData as Record<string, unknown>);
      await sendAndLog(tenantId, customerPhone, `✂️ Remarcar — Qual serviço?\n${list}`, connectionBarberId);
    }
    return;
  }

 // ----- Iniciar sessão se não existir -----
if (!session) {
  // Nome definido no painel (renomear cliente) tem prioridade — ignora P2021 se tabela não existir
  const knownNameFromPanel = await getContactDisplayName(tenantId, phone);

  const existingCustomer = await prisma.appointment.findFirst({
    where: {
      tenant_id: tenantId,
      customer_phone: { contains: phone },
    },
    orderBy: { created_at: 'desc' },
    select: { customer_name: true },
  });

  const knownName = knownNameFromPanel ?? existingCustomer?.customer_name ?? null;

  session = {
    pk: '',
    sk: 'session',
    tenant_id: tenantId,
    phone,
    state: 'INICIO',
    data: {},
    expires_at: 0,
    updated_at: 0,
  } as BotSessionRecord;

  if (knownName && knownName !== 'Cliente WhatsApp') {
    // Cliente já cadastrado — saudação personalizada e vai direto ao menu
    await putBotSession(tenantId, phone, 'INICIO', {
      last_activity_at: Date.now(),
      connection_barber_id: defaultBarberId ?? undefined,
      customer_name: knownName,
    });
    await sendAndLogInteractive(tenantId, customerPhone, getMenuListPayload(businessName, knownName), getMenuMessage(businessName, knownName), defaultBarberId ?? undefined);
    return;
  } else {
    // Cliente novo — pede o nome
    await putBotSession(tenantId, phone, 'AGUARDANDO_NOME', {
      last_activity_at: Date.now(),
      connection_barber_id: defaultBarberId ?? undefined,
    });
    await sendAndLog(tenantId, customerPhone, `Olá! 👋 Bem-vindo à *${businessName}*!\n\nComo posso te chamar?`, defaultBarberId ?? undefined);
    return;
  }
}

  const state = session.state as BotState;
  const data = (session.data || {}) as BotSessionData;
  let reply = '';
  let interactiveList: InteractiveListPayload | null = null;
  let nextState: BotState = state;
  let nextData: BotSessionData = { ...data, last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? data.connection_barber_id };

  switch (state) {
    case 'INICIO': {
      if (data.expired_awaiting_reconfirm) {
        if (isConfirmYes(text)) {
          nextData = { customer_name: data.customer_name, last_activity_at: Date.now() };
          delete nextData.expired_awaiting_reconfirm;
          reply = getMenuMessage(businessName, nextData.customer_name);
          interactiveList = getMenuListPayload(businessName, nextData.customer_name);
          nextState = 'INICIO';
        } else if (isConfirmNo(text)) {
          reply = 'Ok, quando quiser é só mandar uma mensagem. 👋';
          nextData = { last_activity_at: Date.now() };
          nextState = 'INICIO';
          delete nextData.expired_awaiting_reconfirm;
        } else {
          reply = 'Responda S para recomeçar ou N para sair.';
        }
        break;
      }

      const choice = text.replace(/\D/g, '');
      if (choice === '1') {
        const services = tenant.services;
        reply = `✂️ Qual serviço você quer?\n${services.map((s, i) => `${i + 1}️⃣ ${s.name} — R$ ${s.price}`).join('\n')}`;
        interactiveList = {
          body: '✂️ Qual serviço você quer?',
          button: 'Exibir opções',
          sections: [{ rows: services.map((s, i) => ({ id: String(i + 1), title: `${s.name} — R$ ${s.price}` })) }],
        };
        nextState = 'AGUARDANDO_SERVICO';
      } else if (choice === '2') {
        await handleListAppointments(tenantId, customerPhone, connectionBarberId);
        return;
      } else if (choice === '3') {
        reply = 'Para cancelar, digite: CANCELAR #código\nEx: CANCELAR A3F8K2';
      } else if (choice === '4') {
        const appointments = await prisma.appointment.findMany({
          where: {
            tenant_id: tenantId,
            customer_phone: { contains: phone },
            status: { notIn: ['cancelled', 'no_show'] },
            appointment_date: { gte: new Date() },
          },
          include: { barber: true, service: true },
          orderBy: { appointment_date: 'asc' },
          take: 5,
        });
        if (appointments.length === 0) {
          reply = 'Você não tem agendamentos futuros para remarcar. Quer agendar um novo? Digite 1.';
        } else {
          const list = appointments
            .map(
              (a, i) =>
                `${i + 1}️⃣ #${a.id.slice(0, 8).toUpperCase()} — ${a.appointment_date.toLocaleDateString('pt-BR')} ${a.appointment_date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })} — ${a.service?.name ?? '-'} — ${a.barber.name}`
            )
            .join('\n');
          reply = `📅 Qual agendamento deseja remarcar?\n${list}`;
          nextState = 'AGUARDANDO_REAGENDAMENTO';
        }
      } else if (choice === '5') {
        reply = 'Em breve um atendente responderá. Aguarde! 👋';
      } else if (choice === '6') {
        reply = 'Como deseja ser chamado(a)?';
        nextState = 'AGUARDANDO_NOME';
      } else {
        if (!data.customer_name && text.length > 0 && !/^[1-6]\s*$/.test(text)) {
          reply = 'Como posso te chamar? (ou digite 1 para pular)';
          nextState = 'AGUARDANDO_NOME';
        } else {
          const quick = parseQuickBook(text, tenant.services, getTodayBrazil());
          if (quick && data.customer_name) {
            const slotsAtTime = await getSlotsAtTime(tenantId, quick.dateStr, quick.hour, quick.minute, undefined);
            if (slotsAtTime.length > 0) {
              const slot = slotsAtTime[0];
              const service = tenant.services.find((s) => s.id === quick.service_id);
              const barber = tenant.barbers.find((b) => b.id === slot.barber_id);
              nextData.service_id = quick.service_id;
              nextData.date = quick.dateStr;
              nextData.slot_id = slot.id;
              nextData.barber_id = slot.barber_id;
              nextState = 'AGUARDANDO_CONFIRMACAO';
              reply = `✅ *Resumo:*\n✂️ Serviço: ${service?.name ?? '-'}\n👤 Barbeiro: ${barber?.name ?? '-'}\n📅 Data: ${formatDateBR(quick.dateStr)}\n⏰ Horário: ${slot.time}\n\nConfirma? (S/N)`;
            } else {
              reply = `Não temos horário às ${String(quick.hour).padStart(2, '0')}:${String(quick.minute).padStart(2, '0')} no dia ${formatDateBR(quick.dateStr)}. Quer escolher outro? Digite 1 para agendar.`;
              interactiveList = getMenuListPayload(businessName, data.customer_name);
            }
          } else {
            reply = getMenuMessage(businessName, data.customer_name);
            interactiveList = getMenuListPayload(businessName, data.customer_name);
          }
        }
      }
      break;
    }

    case 'AGUARDANDO_NOME': {
      const name = text.trim();
      if (name === '1' || name === '') {
        nextData.customer_name = 'Cliente';
      } else {
        nextData.customer_name = name;
      }
      reply = getMenuMessage(businessName, nextData.customer_name);
      interactiveList = getMenuListPayload(businessName, nextData.customer_name);
      nextState = 'INICIO';
      break;
    }

    case 'AGUARDANDO_SERVICO': {
      const idx = parseInt(text.replace(/\D/g, ''), 10);
      const services = tenant.services;
      if (idx >= 1 && idx <= services.length) {
        nextData.service_id = services[idx - 1].id;
        const barbers = tenant.barbers;
        reply = `👤 Com qual barbeiro?\n${barbers.map((b, i) => `${i + 1}️⃣ ${b.name}`).join('\n')}\n0️⃣ Qualquer disponível`;
        interactiveList = {
          body: '👤 Com qual barbeiro?',
          button: 'Exibir opções',
          sections: [
            {
              rows: [
                ...barbers.map((b, i) => ({ id: String(i + 1), title: b.name })),
                { id: '0', title: 'Qualquer disponível' },
              ],
            },
          ],
        };
        nextState = 'AGUARDANDO_BARBEIRO';
      } else {
        reply = `Opção inválida. Digite 1, 2 ou ${services.length}:\n${services.map((s, i) => `${i + 1}️⃣ ${s.name}`).join('\n')}`;
        interactiveList = {
          body: `✂️ Qual serviço você quer?`,
          button: 'Exibir opções',
          sections: [{ rows: services.map((s, i) => ({ id: String(i + 1), title: `${s.name} — R$ ${s.price}` })) }],
        };
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
        reply = `Opção inválida. Digite 0 ou 1 a ${barbers.length}:\n${barbers.map((b, i) => `${i + 1}️⃣ ${b.name}`).join('\n')}\n0️⃣ Qualquer disponível`;
        interactiveList = {
          body: '👤 Com qual barbeiro?',
          button: 'Exibir opções',
          sections: [{ rows: [...barbers.map((b, i) => ({ id: String(i + 1), title: b.name })), { id: '0', title: 'Qualquer disponível' }] }],
        };
        break;
      }
      const todayStr = getTodayBrazil();
      const next3 = [todayStr, addDaysBrazil(todayStr, 1), addDaysBrazil(todayStr, 2)].map((dateStr) => {
        const d = new Date(dateStr + 'T12:00:00.000Z');
        return d.toLocaleDateString('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' });
      });
      reply = `📅 Qual data? (ex: hoje, amanhã, 15/06 ou 15/06/2025)\nOu:\n${next3.map((d, i) => `${i + 1}️⃣ ${d}`).join('\n')}`;
      interactiveList = {
        body: '📅 Qual data? (ex: hoje, amanhã ou DD/MM)',
        button: 'Exibir opções',
        sections: [{ rows: next3.map((d, i) => ({ id: String(i + 1), title: d })) }],
      };
      nextState = 'AGUARDANDO_DATA';
      break;
    }

    case 'AGUARDANDO_DATA': {
      // "5" / "Falar com atendente" já tratados no bloco global acima
      let dateStr: string | null = null;
      const choice = text.replace(/\D/g, '');
      if (choice === '1' || choice === '2' || choice === '3') {
        const todayBrazil = getTodayBrazil();
        const idx = parseInt(choice, 10) - 1;
        dateStr = idx === 0 ? todayBrazil : addDaysBrazil(todayBrazil, idx);
      } else {
        dateStr = parseUserDate(text);
      }
      if (dateStr) {
        nextData.date = dateStr;
        const slots = await getAvailableSlots(tenantId, nextData.barber_id ?? undefined, dateStr);
        if (slots.length === 0) {
          const nextDates = await getNextDatesWithSlots(tenantId, nextData.barber_id ?? undefined, dateStr);
          if (nextDates.length > 0) {
            const sug = nextDates.map((d, i) => `${i + 1}️⃣ ${formatDateBR(d)}`).join('\n');
            reply = `Sem horários para ${formatDateBR(dateStr)}. Quer tentar outra data?\n${sug}`;
          } else {
            reply = `Sem horários para ${formatDateBR(dateStr)}. Tente outra data (ex: amanhã ou 15/06).`;
          }
        } else {
          const list = slots.slice(0, 10).map((s, i) => `${i + 1}️⃣ ${s.time}`).join('\n');
          reply = `⏰ Horários disponíveis em ${formatDateBR(dateStr)}:\n${list}`;
          interactiveList = {
            body: `⏰ Horários disponíveis em ${formatDateBR(dateStr)}:`,
            button: 'Exibir horários',
            sections: [{ rows: slots.slice(0, 10).map((s, i) => ({ id: String(i + 1), title: s.time })) }],
          };
          nextState = 'AGUARDANDO_SLOT';
        }
      } else {
        reply = 'Data inválida. Use: hoje, amanhã, DD/MM ou DD/MM/AAAA';
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
        reply = `✅ *Resumo:*\n✂️ Serviço: ${service?.name ?? '-'}\n👤 Barbeiro: ${barber?.name ?? '-'}\n📅 Data: ${formatDateBR(nextData.date!)}\n⏰ Horário: ${slot.time}\n\nConfirma? (S/N)`;
        nextState = 'AGUARDANDO_CONFIRMACAO';
      } else {
        reply = `Opção inválida. Digite 1 a ${slots.length}:\n${slots.slice(0, 10).map((s, i) => `${i + 1}️⃣ ${s.time}`).join('\n')}`;
        interactiveList = {
          body: `⏰ Horários disponíveis em ${formatDateBR(nextData.date!)}:`,
          button: 'Exibir horários',
          sections: [{ rows: slots.slice(0, 10).map((s, i) => ({ id: String(i + 1), title: s.time })) }],
        };
      }
      break;
    }

    case 'AGUARDANDO_CONFIRMACAO': {
      if (isConfirmYes(text)) {
        const rescheduleId = nextData.rescheduling_appointment_id;
        if (rescheduleId) {
          await cancelAppointmentById(tenantId, rescheduleId);
        }
        const appointment = await createAppointment(tenantId, phone, nextData);
        const slot = await prisma.slot.findUnique({
          where: { id: nextData.slot_id! },
          select: { start_time: true },
        });
        const timeStr = slot ? slot.start_time.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }) : '';
        const service = tenant.services.find((s) => s.id === nextData.service_id);
        const barber = nextData.barber_id
          ? tenant.barbers.find((b) => b.id === nextData.barber_id)
          : tenant.barbers[0];
        const code = appointment.id.slice(0, 8).toUpperCase();

        reply =
          `✅ *Agendamento confirmado!*\n\n` +
          `✂️ Serviço: ${service?.name ?? '-'}\n` +
          `👤 Barbeiro: ${barber?.name ?? '-'}\n` +
          `📅 Data: ${formatDateLongBR(nextData.date!, timeStr)}\n` +
          `📍 ${businessName}\n\n` +
          `Código: #${code}\n` +
          `Para cancelar: CANCELAR #${code}`;

        nextState = 'CONCLUIDO';
        nextData = {};
      } else if (isConfirmNo(text)) {
        reply = 'Agendamento não realizado. Quer tentar de novo? Digite 1 para agendar.';
        nextState = 'INICIO';
        nextData = {};
      } else {
        reply = 'Responda S para confirmar ou N para cancelar.';
      }
      break;
    }

    case 'AGUARDANDO_CONFIRMACAO_ATENDENTE': {
      if (isConfirmYes(text)) {
        await createAttendantRequest(tenantId, customerPhone, data.customer_name);
        reply = '✅ Pedido enviado! Em breve um atendente entrará em contato. Aguarde! 👋';
        nextState = 'INICIO';
        nextData = { customer_name: data.customer_name, last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? undefined };
      } else if (isConfirmNo(text)) {
        reply = getMenuMessage(businessName, data.customer_name);
        nextState = 'INICIO';
        nextData = { customer_name: data.customer_name, last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? undefined };
      } else {
        reply = 'Responda *S* para falar com um atendente ou *N* para voltar ao menu.';
      }
      break;
    }

    case 'AGUARDANDO_REAGENDAMENTO': {
      const appointments = await prisma.appointment.findMany({
        where: {
          tenant_id: tenantId,
          customer_phone: { contains: phone },
          status: { notIn: ['cancelled', 'no_show'] },
          appointment_date: { gte: new Date() },
        },
        include: { barber: true, service: true },
        orderBy: { appointment_date: 'asc' },
        take: 5,
      });
      const idx = parseInt(text.replace(/\D/g, ''), 10);
      if (idx >= 1 && idx <= appointments.length) {
        const appt = appointments[idx - 1];
        nextData.rescheduling_appointment_id = appt.id;
        nextData.service_id = appt.service_id ?? undefined;
        nextData.barber_id = appt.barber_id;
        const todayStr = getTodayBrazil();
        const next3 = [todayStr, addDaysBrazil(todayStr, 1), addDaysBrazil(todayStr, 2)].map((dateStr) => {
          const d = new Date(dateStr + 'T12:00:00.000Z');
          return d.toLocaleDateString('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' });
        });
        reply = `📅 Nova data? (ex: hoje, amanhã, DD/MM)\n${next3.map((d, i) => `${i + 1}️⃣ ${d}`).join('\n')}`;
        nextState = 'AGUARDANDO_DATA';
      } else {
        reply = `Opção inválida. Digite 1 a ${appointments.length}.`;
      }
      break;
    }

    case 'AGUARDANDO_RECOMECAR':
      nextState = 'INICIO';
      reply = getMenuMessage(businessName, data.customer_name);
      break;

    case 'CONCLUIDO':
      reply = getMenuMessage(businessName, data.customer_name);
      interactiveList = getMenuListPayload(businessName, data.customer_name);
      nextState = 'INICIO';
      break;
  }

  await updateBotSessionState(tenantId, phone, nextState, nextData as Record<string, unknown>);
  if (interactiveList) {
    await sendAndLogInteractive(tenantId, customerPhone, interactiveList, reply || interactiveList.body, connectionBarberId);
  } else {
    await sendAndLog(tenantId, customerPhone, reply, connectionBarberId);
  }
}

/**
 * Mensagem inicial (ex.: primeira interação)
 */
export async function sendWelcomeMessage(tenantId: string, customerPhone: string, connectionBarberId?: string | null): Promise<void> {
  const tenant = await prisma.tenant.findUnique({
    where: { id: tenantId },
    select: { business_name: true, name: true },
  });
  const businessName = tenant?.business_name || tenant?.name || 'Barbearia';
  const msg = getMenuMessage(businessName);
  await putBotSession(tenantId, normalizePhone(customerPhone), 'INICIO', { last_activity_at: Date.now(), connection_barber_id: connectionBarberId ?? undefined });
  await sendAndLog(tenantId, customerPhone, msg, connectionBarberId);
}
