'use client';

import { useEffect, useState } from 'react';

interface Appointment {
  id: string;
  customer_name: string;
  customer_phone: string;
  appointment_date: string;
  status: string;
  barber: { id: string; name: string };
  service: { id: string; name: string } | null;
}

export default function AppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'upcoming' | 'all'>('upcoming');

  useEffect(() => {
    const url =
      filter === 'upcoming'
        ? '/api/app/appointments?upcoming=true'
        : '/api/app/appointments?date=' + new Date().toISOString().slice(0, 10);
    fetch(url, {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then((r) => r.json())
      .then((d) => setAppointments(d.appointments || []))
      .catch(() => setAppointments([]))
      .finally(() => setLoading(false));
  }, [filter]);

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Agendamentos</h1>
      <p className="text-white/60 mb-8 font-body">Lista de todos os agendamentos</p>

      <div className="flex gap-2 mb-6">
        <button
          onClick={() => setFilter('upcoming')}
          className={`px-4 py-2 rounded-lg font-medium transition ${
            filter === 'upcoming'
              ? 'bg-[#F5C518] text-black'
              : 'bg-white/10 text-white hover:bg-white/20'
          }`}
        >
          Próximos 7 dias
        </button>
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded-lg font-medium transition ${
            filter === 'all'
              ? 'bg-[#F5C518] text-black'
              : 'bg-white/10 text-white hover:bg-white/20'
          }`}
        >
          Hoje
        </button>
      </div>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-white/60">Carregando...</div>
        ) : appointments.length === 0 ? (
          <div className="p-12 text-center text-white/50">Nenhum agendamento encontrado</div>
        ) : (
          <div className="divide-y divide-white/5">
            {appointments.map((a) => (
              <div
                key={a.id}
                className="p-6 flex items-center justify-between hover:bg-white/5 transition"
              >
                <div>
                  <p className="font-medium text-white">{a.customer_name}</p>
                  <p className="text-white/60 text-sm">
                    {a.customer_phone} • {a.barber.name} • {a.service?.name ?? '-'}
                  </p>
                  <p className="text-white/40 text-sm mt-1">
                    {new Date(a.appointment_date).toLocaleString('pt-BR')}
                  </p>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium
                    ${
                      a.status === 'confirmed'
                        ? 'bg-blue-500/20 text-blue-400'
                        : a.status === 'pending'
                        ? 'bg-amber-500/20 text-amber-400'
                        : a.status === 'cancelled'
                        ? 'bg-red-500/20 text-red-400'
                        : 'bg-white/10 text-white/70'
                    }`}
                >
                  {a.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
