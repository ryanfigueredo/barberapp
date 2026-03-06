'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Calendar, CalendarRange, Users, Banknote, Clock } from 'lucide-react';

interface Stats {
  today: number;
  week: number;
  barbers: number;
  revenue_today?: number;
  revenue_week?: number;
  upcoming_today: Array<{
    id: string;
    customer_name: string;
    appointment_date: string;
    status: string;
    barber: { id: string; name: string };
    service: { id: string; name: string; price?: number } | null;
  }>;
}

function formatMoney(value: number): string {
  if (value === 0) return 'R$ 0';
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 }).format(value);
}

export default function InicioPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/stats', {
      headers: {
        'X-API-Key': (typeof window !== 'undefined' ? localStorage.getItem('api_key') : '') || '',
      },
    })
      .then((r) =>
        r.ok
          ? r.json()
          : { today: 0, week: 0, barbers: 0, revenue_today: 0, revenue_week: 0, upcoming_today: [] }
      )
      .then(setStats)
      .catch(() =>
        setStats({
          today: 0,
          week: 0,
          barbers: 0,
          revenue_today: 0,
          revenue_week: 0,
          upcoming_today: [],
        })
      )
      .finally(() => setLoading(false));
  }, []);

  const formatTime = (iso: string) =>
    new Date(iso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[var(--barber-gold)] mb-2">Início</h1>
      <p className="text-white/60 mb-8 font-body">Visão geral da barbearia</p>

      {loading ? (
        <div className="text-white/60">Carregando...</div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
            <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-[var(--barber-gold)]/20 flex items-center justify-center shrink-0">
                <Calendar className="w-5 h-5 text-[var(--barber-gold)]" />
              </div>
              <div className="min-w-0">
                <p className="text-white/60 text-xs font-medium uppercase tracking-wide">Hoje</p>
                <p className="text-2xl font-display font-bold text-[var(--barber-gold)] mt-0.5">{stats?.today ?? 0}</p>
                <p className="text-white/40 text-xs mt-0.5">agendamentos</p>
              </div>
            </div>

            <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-[var(--barber-gold)]/20 flex items-center justify-center shrink-0">
                <CalendarRange className="w-5 h-5 text-[var(--barber-gold)]" />
              </div>
              <div className="min-w-0">
                <p className="text-white/60 text-xs font-medium uppercase tracking-wide">Esta semana</p>
                <p className="text-2xl font-display font-bold text-[var(--barber-gold)] mt-0.5">{stats?.week ?? 0}</p>
                <p className="text-white/40 text-xs mt-0.5">agendamentos</p>
              </div>
            </div>

            <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-[var(--barber-gold)]/20 flex items-center justify-center shrink-0">
                <Users className="w-5 h-5 text-[var(--barber-gold)]" />
              </div>
              <div className="min-w-0">
                <p className="text-white/60 text-xs font-medium uppercase tracking-wide">Barbeiros</p>
                <p className="text-2xl font-display font-bold text-[var(--barber-gold)] mt-0.5">{stats?.barbers ?? 0}</p>
                <p className="text-white/40 text-xs mt-0.5">ativos</p>
              </div>
            </div>

            <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-[var(--barber-gold)]/20 flex items-center justify-center shrink-0">
                <Banknote className="w-5 h-5 text-[var(--barber-gold)]" />
              </div>
              <div className="min-w-0">
                <p className="text-white/60 text-xs font-medium uppercase tracking-wide">Faturamento hoje</p>
                <p className="text-xl font-display font-bold text-[var(--barber-gold)] mt-0.5">
                  {formatMoney(stats?.revenue_today ?? 0)}
                </p>
                <p className="text-white/40 text-xs mt-0.5">concluídos</p>
              </div>
            </div>

            <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-[var(--barber-gold)]/20 flex items-center justify-center shrink-0">
                <Banknote className="w-5 h-5 text-[var(--barber-gold)]" />
              </div>
              <div className="min-w-0">
                <p className="text-white/60 text-xs font-medium uppercase tracking-wide">Faturamento semana</p>
                <p className="text-xl font-display font-bold text-[var(--barber-gold)] mt-0.5">
                  {formatMoney(stats?.revenue_week ?? 0)}
                </p>
                <p className="text-white/40 text-xs mt-0.5">concluídos</p>
              </div>
            </div>
          </div>

          <div className="bg-[#1C1C1E] rounded-xl border border-white/5 overflow-hidden mb-8">
            <div className="p-5 border-b border-white/5 flex items-center gap-2">
              <Clock className="w-5 h-5 text-[var(--barber-gold)]" />
              <div>
                <h2 className="font-display text-xl text-white">Próximos hoje</h2>
                <p className="text-white/60 text-sm">Agendamentos do dia</p>
              </div>
            </div>
            <div className="divide-y divide-white/5">
              {(stats?.upcoming_today ?? []).length === 0 ? (
                <div className="p-12 text-center text-white/50">Nenhum agendamento restante hoje</div>
              ) : (
                stats?.upcoming_today.map((a) => (
                  <div
                    key={a.id}
                    className="p-4 flex items-center gap-4 hover:bg-white/5 transition"
                  >
                    <span className="text-[var(--barber-gold)] font-mono font-semibold text-sm w-12 shrink-0">
                      {formatTime(a.appointment_date)}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="font-medium text-white">{a.customer_name}</p>
                      <p className="text-white/60 text-sm">
                        {a.barber.name} · {a.service?.name ?? '-'}
                      </p>
                    </div>
                    <span
                      className={`shrink-0 px-3 py-1 rounded-full text-xs font-medium
                        ${
                          a.status === 'confirmed'
                            ? 'bg-blue-500/20 text-blue-400'
                            : a.status === 'pending'
                            ? 'bg-amber-500/20 text-amber-400'
                            : 'bg-white/10 text-white/70'
                        }`}
                    >
                      {a.status}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="flex flex-wrap gap-3">
            <Link
              href="/agendamentos"
              className="inline-flex items-center gap-2 px-6 py-3 bg-[var(--barber-gold)] text-black font-semibold rounded-lg hover:opacity-90 transition"
            >
              <Calendar className="w-4 h-4" />
              Ver calendário e agendamentos
            </Link>
            <Link
              href="/barbeiros"
              className="inline-flex items-center gap-2 px-6 py-3 border border-white/20 text-white rounded-lg hover:bg-white/5 transition"
            >
              <Users className="w-4 h-4" />
              Barbeiros
            </Link>
          </div>
        </>
      )}
    </div>
  );
}
