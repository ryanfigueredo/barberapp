'use client';

import { useEffect, useState } from 'react';
import { Calendar, CalendarDays, Users, MessageCircle } from 'lucide-react';

type ViewMode = 'calendar' | 'week' | 'daily';

interface Appointment {
  id: string;
  customer_name: string;
  customer_phone?: string;
  appointment_date: string;
  status: string;
  barber: { id: string; name: string };
  service: { id: string; name: string } | null;
}

interface Barber {
  id: string;
  name: string;
}

const monthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

const weekDayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

function getWeekStart(d: Date): Date {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  date.setDate(diff);
  date.setHours(0, 0, 0, 0);
  return date;
}

function getWeekEnd(weekStart: Date): Date {
  const end = new Date(weekStart);
  end.setDate(end.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
}

function getApiKey(): string {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem('api_key') || '';
}

function whatsAppUrl(phone: string): string {
  const d = (phone || '').replace(/\D/g, '');
  const num = d.startsWith('55') ? d : '55' + d;
  return `https://wa.me/${num}`;
}

function statusClass(status: string): string {
  switch (status) {
    case 'confirmed': return 'bg-blue-500/20 text-blue-400';
    case 'pending': return 'bg-amber-500/20 text-amber-400';
    case 'completed': return 'bg-green-500/20 text-green-400';
    case 'cancelled': return 'bg-red-500/20 text-red-400';
    default: return 'bg-white/10 text-white/70';
  }
}

export default function AgendamentosPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('calendar');
  const [calendarBaseDate, setCalendarBaseDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [panelOpen, setPanelOpen] = useState(false);
  const [daysWithDots, setDaysWithDots] = useState<Record<string, { count: number }>>({});
  const [dayAppointments, setDayAppointments] = useState<Appointment[]>([]);
  const [weekStart, setWeekStart] = useState(() => getWeekStart(new Date()));
  const [weekAppointments, setWeekAppointments] = useState<Appointment[]>([]);
  const [dailyDate, setDailyDate] = useState(new Date());
  const [dailyAppointments, setDailyAppointments] = useState<Appointment[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);

  const apiKey = getApiKey();
  const headers = { 'X-API-Key': apiKey };

  const year = calendarBaseDate.getFullYear();
  const month = calendarBaseDate.getMonth();
  const monthStr = `${year}-${String(month + 1).padStart(2, '0')}`;

  useEffect(() => {
    if (viewMode !== 'calendar') return;
    fetch(`/api/app/appointments/month?month=${monthStr}`, { headers })
      .then((r) => r.json())
      .then((d) => setDaysWithDots(d.days_with_appointments || {}))
      .catch(() => setDaysWithDots({}));
  }, [viewMode, monthStr, apiKey]);

  useEffect(() => {
    if (!selectedDate) {
      setDayAppointments([]);
      return;
    }
    const dateStr = selectedDate.toISOString().slice(0, 10);
    fetch(`/api/app/appointments?date=${dateStr}`, { headers })
      .then((r) => r.json())
      .then((d) => setDayAppointments(d.appointments || []))
      .catch(() => setDayAppointments([]));
  }, [selectedDate, apiKey]);

  useEffect(() => {
    if (viewMode !== 'week') return;
    const start = weekStart.toISOString().slice(0, 10);
    const end = getWeekEnd(weekStart).toISOString().slice(0, 10);
    fetch(`/api/app/appointments?start=${start}&end=${end}`, { headers })
      .then((r) => r.json())
      .then((d) => setWeekAppointments(d.appointments || []))
      .catch(() => setWeekAppointments([]));
  }, [viewMode, weekStart, apiKey]);

  useEffect(() => {
    if (viewMode !== 'daily') return;
    const dateStr = dailyDate.toISOString().slice(0, 10);
    Promise.all([
      fetch(`/api/app/appointments?date=${dateStr}`, { headers }).then((r) => r.json()),
      fetch('/api/app/barbers', { headers }).then((r) => r.json()),
    ])
      .then(([apptsRes, barbersList]) => {
        setDailyAppointments(apptsRes.appointments || []);
        setBarbers(Array.isArray(barbersList) ? barbersList : []);
      })
      .catch(() => {
        setDailyAppointments([]);
        setBarbers([]);
      });
  }, [viewMode, dailyDate, apiKey]);

  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const days: (number | null)[] = [];
  for (let i = 0; i < firstDay; i++) days.push(null);
  for (let d = 1; d <= daysInMonth; d++) days.push(d);

  const handleDayClick = (d: number) => {
    setSelectedDate(new Date(year, month, d));
    setPanelOpen(true);
  };

  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart);
    d.setDate(d.getDate() + i);
    return d;
  });

  const appointmentsByBarber = barbers.map((barber) => ({
    barber,
    appointments: dailyAppointments.filter((a) => a.barber.id === barber.id),
  }));

  return (
    <div className="flex-1 flex flex-col min-h-0 overflow-hidden p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2 shrink-0">Agendamentos</h1>
      <p className="text-white/60 mb-6 font-body shrink-0">Visualize e gerencie agendamentos</p>

      <div className="flex flex-wrap gap-2 mb-4 shrink-0">
        <button
          onClick={() => setViewMode('calendar')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition ${
            viewMode === 'calendar' ? 'bg-[#F5C518] text-black' : 'bg-white/10 text-white hover:bg-white/20'
          }`}
        >
          <Calendar className="w-4 h-4" />
          Calendário (mês)
        </button>
        <button
          onClick={() => setViewMode('week')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition ${
            viewMode === 'week' ? 'bg-[#F5C518] text-black' : 'bg-white/10 text-white hover:bg-white/20'
          }`}
        >
          <CalendarDays className="w-4 h-4" />
          Esteira semanal
        </button>
        <button
          onClick={() => setViewMode('daily')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition ${
            viewMode === 'daily' ? 'bg-[#F5C518] text-black' : 'bg-white/10 text-white hover:bg-white/20'
          }`}
        >
          <Users className="w-4 h-4" />
          Diário por barbeiro
        </button>
      </div>

      {viewMode === 'calendar' && (
        <div className="flex-1 min-h-0 flex flex-col overflow-hidden bg-[#1A1A1A] rounded-xl border border-white/5">
          {panelOpen && selectedDate && (
            <div className="shrink-0 mx-6 mt-6 mb-2 overflow-hidden animate-slide-up-from-bottom">
              <div className="rounded-xl border border-[#F5C518]/30 bg-[#0A0A0A] shadow-xl shadow-black/40">
                <div className="p-4 flex items-center justify-between border-b border-white/10">
                  <h2 className="font-display text-lg text-[#F5C518]">
                    Agendamentos de {selectedDate.toLocaleDateString('pt-BR')}
                  </h2>
                  <button
                    onClick={() => setPanelOpen(false)}
                    className="w-10 h-10 rounded-full flex items-center justify-center text-white/80 hover:text-white hover:bg-white/10 transition-all duration-200 hover:rotate-90 focus:outline-none focus:ring-2 focus:ring-[#F5C518]/50"
                    aria-label="Fechar"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
                <div className="max-h-64 overflow-y-auto divide-y divide-white/5">
                  {dayAppointments.length === 0 ? (
                    <div className="p-8 text-center text-white/50">Nenhum agendamento neste dia</div>
                  ) : (
                    dayAppointments.map((a) => (
                      <div key={a.id} className="p-4 flex items-center justify-between hover:bg-white/5 transition-colors">
                        <div>
                          <p className="font-medium text-white">{a.customer_name}</p>
                          <p className="text-white/60 text-sm">
                            {new Date(a.appointment_date).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}{' '}
                            • {a.barber.name} • {a.service?.name ?? '-'}
                          </p>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          {a.customer_phone && (
                            <a
                              href={whatsAppUrl(a.customer_phone)}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="p-2 rounded-lg bg-green-500/20 text-green-400 hover:bg-green-500/30 transition"
                              title="Chamar no WhatsApp"
                            >
                              <MessageCircle className="w-4 h-4" />
                            </a>
                          )}
                          <span className={`px-3 py-1 rounded-full text-xs ${statusClass(a.status)}`}>
                            {a.status}
                          </span>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          )}

          <div className="p-6 border-b border-white/5 flex items-center justify-between flex-wrap gap-4 shrink-0">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setCalendarBaseDate(new Date(year, month - 1))}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                ←
              </button>
              <span className="font-display text-xl text-white">
                {monthNames[month]} {year}
              </span>
              <button
                onClick={() => setCalendarBaseDate(new Date(year, month + 1))}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                →
              </button>
              <button
                onClick={() => setCalendarBaseDate(new Date())}
                className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
              >
                Hoje
              </button>
            </div>
          </div>

          <div className="flex-1 min-h-0 overflow-auto p-6">
            <div className="grid grid-cols-7 gap-2 mb-3">
              {weekDayNames.map((d) => (
                <div key={d} className="text-center text-white/60 text-xs font-medium py-2">{d}</div>
              ))}
              {days.map((d, i) => {
                if (d === null) return <div key={i} />;
                const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
                const hasAppointments = daysWithDots[dateStr];
                const isSelected =
                  selectedDate &&
                  selectedDate.getDate() === d &&
                  selectedDate.getMonth() === month &&
                  selectedDate.getFullYear() === year;
                const isToday =
                  new Date().getDate() === d &&
                  new Date().getMonth() === month &&
                  new Date().getFullYear() === year;
                return (
                  <button
                    key={i}
                    onClick={() => handleDayClick(d)}
                    className={`h-12 min-w-0 rounded-lg flex flex-col items-center justify-center transition text-sm
                      ${
                        isSelected
                          ? 'bg-[#F5C518] text-black'
                          : isToday
                          ? 'border border-[#F5C518] text-white'
                          : hasAppointments
                          ? 'bg-white/10 text-white hover:bg-white/20'
                          : 'text-white/60 hover:bg-white/5'
                      }`}
                  >
                    <span className="font-medium leading-tight">{d}</span>
                    {hasAppointments && <span className="w-1.5 h-1.5 rounded-full bg-[#F5C518] mt-1" />}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {viewMode === 'week' && (
        <div className="flex-1 min-h-0 flex flex-col overflow-hidden bg-[#1A1A1A] rounded-xl border border-white/5">
          <div className="p-4 border-b border-white/5 flex items-center justify-between flex-wrap gap-4 shrink-0">
            <div className="flex items-center gap-2">
              <button
                onClick={() => setWeekStart(new Date(weekStart.getTime() - 7 * 24 * 60 * 60 * 1000))}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                ←
              </button>
              <span className="font-display text-lg text-white">
                Semana de {weekStart.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })} a{' '}
                {getWeekEnd(weekStart).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' })}
              </span>
              <button
                onClick={() => setWeekStart(new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000))}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                →
              </button>
            </div>
            <button
              onClick={() => setWeekStart(getWeekStart(new Date()))}
              className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
            >
              Esta semana
            </button>
          </div>
          <div className="flex-1 min-h-0 flex flex-col overflow-hidden">
            <div className="flex flex-1 min-h-0 overflow-x-auto overflow-y-hidden">
              <div className="flex min-w-max h-full">
              {weekDays.map((day) => {
                const dateStr = day.toISOString().slice(0, 10);
                const dayAppts = weekAppointments.filter((a) => a.appointment_date.startsWith(dateStr));
                const isToday =
                  day.getDate() === new Date().getDate() &&
                  day.getMonth() === new Date().getMonth() &&
                  day.getFullYear() === new Date().getFullYear();
                return (
                  <div
                    key={dateStr}
                    className={`w-52 shrink-0 border-r border-white/5 last:border-r-0 flex flex-col ${isToday ? 'bg-[#F5C518]/10' : ''}`}
                  >
                    <div className="p-3 border-b border-white/5 text-center shrink-0">
                      <p className="text-white/60 text-xs uppercase">{weekDayNames[day.getDay()]}</p>
                      <p className="font-display text-lg text-white">{day.getDate()}</p>
                      <p className="text-white/50 text-sm">{day.toLocaleDateString('pt-BR', { month: 'short' })}</p>
                    </div>
                    <div className="flex-1 min-h-0 overflow-y-auto p-2 space-y-2">
                      {dayAppts.length === 0 ? (
                        <p className="text-white/40 text-sm text-center py-4">Nenhum</p>
                      ) : (
                        dayAppts
                          .sort(
                            (a, b) =>
                              new Date(a.appointment_date).getTime() - new Date(b.appointment_date).getTime()
                          )
                          .map((a) => (
                            <div key={a.id} className="p-2 rounded-lg bg-white/5 text-left flex items-start justify-between gap-1">
                              <div className="min-w-0 flex-1">
                                <p className="font-medium text-white text-sm truncate">{a.customer_name}</p>
                                <p className="text-white/60 text-xs">
                                  {new Date(a.appointment_date).toLocaleTimeString('pt-BR', {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}{' '}
                                  • {a.barber.name}
                                </p>
                                <span className={`inline-block mt-1 px-2 py-0.5 rounded text-xs ${statusClass(a.status)}`}>
                                  {a.status}
                                </span>
                              </div>
                              {a.customer_phone && (
                                <a
                                  href={whatsAppUrl(a.customer_phone)}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="p-1.5 rounded bg-green-500/20 text-green-400 hover:bg-green-500/30 shrink-0"
                                  title="WhatsApp"
                                >
                                  <MessageCircle className="w-3.5 h-3.5" />
                                </a>
                              )}
                            </div>
                          ))
                      )}
                    </div>
                  </div>
                );
              })}
              </div>
            </div>
          </div>
        </div>
      )}

      {viewMode === 'daily' && (
        <div className="flex-1 min-h-0 flex flex-col overflow-hidden bg-[#1A1A1A] rounded-xl border border-white/5">
          <div className="p-4 border-b border-white/5 flex items-center justify-between flex-wrap gap-4 shrink-0">
            <div className="flex items-center gap-2">
              <button
                onClick={() => {
                  const d = new Date(dailyDate);
                  d.setDate(d.getDate() - 1);
                  setDailyDate(d);
                }}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                ←
              </button>
              <span className="font-display text-lg text-white min-w-[140px] text-center">
                {dailyDate.toLocaleDateString('pt-BR', { weekday: 'long', day: '2-digit', month: 'long' })}
              </span>
              <button
                onClick={() => {
                  const d = new Date(dailyDate);
                  d.setDate(d.getDate() + 1);
                  setDailyDate(d);
                }}
                className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
              >
                →
              </button>
            </div>
            <button
              onClick={() => setDailyDate(new Date())}
              className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
            >
              Hoje
            </button>
          </div>
          <div className="flex-1 min-h-0 overflow-auto p-4">
            <div className="flex gap-4 min-w-max">
              {appointmentsByBarber.map(({ barber, appointments }) => (
                <div
                  key={barber.id}
                  className="w-72 shrink-0 flex flex-col rounded-xl border border-white/10 bg-[#0A0A0A]/50 overflow-hidden"
                >
                  <div className="p-4 border-b border-white/10 flex items-center gap-2">
                    <Users className="w-5 h-5 text-[#F5C518] shrink-0" />
                    <div className="min-w-0">
                      <h3 className="font-display text-base text-[#F5C518] truncate">{barber.name}</h3>
                      <p className="text-white/50 text-xs">
                        {appointments.length} agendamento{appointments.length !== 1 ? 's' : ''}
                      </p>
                    </div>
                  </div>
                  <div className="p-3 flex-1 space-y-2 min-h-[200px] overflow-y-auto">
                    {appointments.length === 0 ? (
                      <p className="text-white/40 text-sm text-center py-8">Nenhum agendamento</p>
                    ) : (
                      [...appointments]
                        .sort(
                          (a, b) =>
                            new Date(a.appointment_date).getTime() - new Date(b.appointment_date).getTime()
                        )
                        .map((a) => (
                          <div
                            key={a.id}
                            className="p-3 rounded-lg bg-white/5 border border-white/5 hover:border-white/10 transition-colors flex items-start justify-between gap-2"
                          >
                            <div className="min-w-0 flex-1">
                              <p className="font-medium text-white text-sm truncate">{a.customer_name}</p>
                              <p className="text-white/60 text-xs mt-0.5">
                                {new Date(a.appointment_date).toLocaleTimeString('pt-BR', {
                                  hour: '2-digit',
                                  minute: '2-digit',
                                })}{' '}
                                · {a.service?.name ?? '-'}
                              </p>
                              <span className={`inline-block mt-2 px-2 py-0.5 rounded text-xs ${statusClass(a.status)}`}>
                                {a.status}
                              </span>
                            </div>
                            {a.customer_phone && (
                              <a
                                href={whatsAppUrl(a.customer_phone)}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="p-2 rounded-lg bg-green-500/20 text-green-400 hover:bg-green-500/30 shrink-0"
                                title="WhatsApp"
                              >
                                <MessageCircle className="w-4 h-4" />
                              </a>
                            )}
                          </div>
                        ))
                    )}
                  </div>
                </div>
              ))}
            </div>
            {barbers.length === 0 && dailyAppointments.length === 0 && (
              <div className="flex items-center justify-center py-24 text-white/50">Carregando...</div>
            )}
            {barbers.length === 0 && dailyAppointments.length > 0 && (
              <div className="w-72 shrink-0 rounded-xl border border-white/10 bg-[#0A0A0A]/50 overflow-hidden">
                <div className="p-4 border-b border-white/10">
                  <h3 className="font-display text-base text-[#F5C518]">Agendamentos do dia</h3>
                </div>
                <div className="p-3 space-y-2">
                  {dailyAppointments.map((a) => (
                    <div key={a.id} className="p-3 rounded-lg bg-white/5 border border-white/5 flex items-start justify-between gap-2">
                      <div>
                        <p className="font-medium text-white text-sm">{a.customer_name}</p>
                        <p className="text-white/60 text-xs mt-0.5">
                          {new Date(a.appointment_date).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}{' '}
                          · {a.barber.name} · {a.service?.name ?? '-'}
                        </p>
                        <span className={`inline-block mt-2 px-2 py-0.5 rounded text-xs ${statusClass(a.status)}`}>
                          {a.status}
                        </span>
                      </div>
                      {a.customer_phone && (
                        <a
                          href={whatsAppUrl(a.customer_phone)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="p-2 rounded-lg bg-green-500/20 text-green-400 hover:bg-green-500/30 shrink-0"
                          title="WhatsApp"
                        >
                          <MessageCircle className="w-4 h-4" />
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
