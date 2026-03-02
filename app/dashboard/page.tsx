'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface Stats {
  today: number;
  week: number;
  barbers: number;
  upcoming_today: Array<{
    id: string;
    customer_name: string;
    appointment_date: string;
    status: string;
    barber: { id: string; name: string };
    service: { id: string; name: string } | null;
  }>;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/stats', {
      headers: {
        'X-API-Key': (typeof window !== 'undefined' ? localStorage.getItem('api_key') : '') || '',
      },
    })
      .then((r) => (r.ok ? r.json() : { today: 0, week: 0, barbers: 0, upcoming_today: [] }))
      .then(setStats)
      .catch(() => setStats({ today: 0, week: 0, barbers: 0, upcoming_today: [] }))
      .finally(() => setLoading(false));
  }, []);

  const formatTime = (iso: string) =>
    new Date(iso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Dashboard</h1>
      <p className="text-white/60 mb-8 font-body">Visão geral da barbearia</p>

      {loading ? (
        <div className="text-white/60">Carregando...</div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
            <div className="bg-[#1A1A1A] rounded-xl p-6 border border-white/5">
              <p className="text-white/60 text-sm font-body mb-1">Hoje</p>
              <p className="text-3xl font-display text-[#F5C518]">{stats?.today ?? 0}</p>
              <p className="text-white/40 text-sm mt-1">agendamentos</p>
            </div>
            <div className="bg-[#1A1A1A] rounded-xl p-6 border border-white/5">
              <p className="text-white/60 text-sm font-body mb-1">Esta semana</p>
              <p className="text-3xl font-display text-[#F5C518]">{stats?.week ?? 0}</p>
              <p className="text-white/40 text-sm mt-1">agendamentos</p>
            </div>
            <div className="bg-[#1A1A1A] rounded-xl p-6 border border-white/5">
              <p className="text-white/60 text-sm font-body mb-1">Barbeiros ativos</p>
              <p className="text-3xl font-display text-[#F5C518]">{stats?.barbers ?? 0}</p>
            </div>
          </div>

          <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
            <div className="p-6 border-b border-white/5">
              <h2 className="font-display text-xl text-white">Próximos hoje</h2>
              <p className="text-white/60 text-sm mt-1">Agendamentos do dia</p>
            </div>
            <div className="divide-y divide-white/5">
              {(stats?.upcoming_today ?? []).length === 0 ? (
                <div className="p-12 text-center text-white/50">
                  Nenhum agendamento para hoje
                </div>
              ) : (
                stats?.upcoming_today.map((a) => (
                  <div
                    key={a.id}
                    className="p-6 flex items-center justify-between hover:bg-white/5 transition"
                  >
                    <div>
                      <p className="font-medium text-white">{a.customer_name}</p>
                      <p className="text-white/60 text-sm">
                        {formatTime(a.appointment_date)} • {a.barber.name} •{' '}
                        {a.service?.name ?? '-'}
                      </p>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium
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

          <div className="mt-8 flex gap-4">
            <Link
              href="/dashboard/calendar"
              className="px-6 py-3 bg-[#F5C518] text-black font-semibold rounded-lg hover:bg-amber-400 transition"
            >
              Ver calendário
            </Link>
            <Link
              href="/dashboard/appointments"
              className="px-6 py-3 border border-white/20 text-white rounded-lg hover:bg-white/5 transition"
            >
              Ver todos os agendamentos
            </Link>
          </div>
        </>
      )}
    </div>
  );
}
