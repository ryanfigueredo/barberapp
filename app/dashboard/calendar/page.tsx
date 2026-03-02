'use client';

import { useEffect, useState } from 'react';

interface Appointment {
  id: string;
  customer_name: string;
  appointment_date: string;
  status: string;
  barber: { id: string; name: string };
  service: { id: string; name: string } | null;
}

export default function CalendarPage() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [daysWithDots, setDaysWithDots] = useState<Record<string, { count: number }>>({});

  const year = selectedDate.getFullYear();
  const month = selectedDate.getMonth();
  const monthStr = `${year}-${String(month + 1).padStart(2, '0')}`;

  useEffect(() => {
    fetch(`/api/app/appointments/month?month=${monthStr}`, {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then((r) => r.json())
      .then((d) => setDaysWithDots(d.days_with_appointments || {}))
      .catch(() => setDaysWithDots({}));
  }, [monthStr]);

  useEffect(() => {
    const dateStr = selectedDate.toISOString().slice(0, 10);
    fetch(`/api/app/appointments?date=${dateStr}`, {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then((r) => r.json())
      .then((d) => setAppointments(d.appointments || []))
      .catch(() => setAppointments([]));
  }, [selectedDate]);

  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const days: (number | null)[] = [];
  for (let i = 0; i < firstDay; i++) days.push(null);
  for (let d = 1; d <= daysInMonth; d++) days.push(d);

  const prevMonth = () => setSelectedDate(new Date(year, month - 1));
  const nextMonth = () => setSelectedDate(new Date(year, month + 1));
  const goToday = () => setSelectedDate(new Date());

  const monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Calendário</h1>
      <p className="text-white/60 mb-8 font-body">Visualize e gerencie agendamentos</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-4">
            <button
              onClick={prevMonth}
              className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
            >
              ←
            </button>
            <span className="font-display text-xl text-white">
              {monthNames[month]} {year}
            </span>
            <button
              onClick={nextMonth}
              className="w-10 h-10 rounded-lg border border-white/20 text-white hover:bg-white/10 transition"
            >
              →
            </button>
            <button
              onClick={goToday}
              className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
            >
              Hoje
            </button>
          </div>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-7 gap-2 mb-4">
            {['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((d) => (
              <div key={d} className="text-center text-white/60 text-sm font-medium py-2">
                {d}
              </div>
            ))}
            {days.map((d, i) => {
              if (d === null) return <div key={i} />;
              const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
              const hasAppointments = daysWithDots[dateStr];
              const isSelected =
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
                  onClick={() => setSelectedDate(new Date(year, month, d))}
                  className={`aspect-square rounded-lg flex flex-col items-center justify-center transition
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
                  <span className="font-medium">{d}</span>
                  {hasAppointments && (
                    <span className="w-1.5 h-1.5 rounded-full bg-[#F5C518] mt-1" />
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div className="mt-8 bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5">
          <h2 className="font-display text-xl text-white">
            Agendamentos de {selectedDate.toLocaleDateString('pt-BR')}
          </h2>
        </div>
        <div className="divide-y divide-white/5">
          {appointments.length === 0 ? (
            <div className="p-12 text-center text-white/50">Nenhum agendamento neste dia</div>
          ) : (
            appointments.map((a) => (
              <div key={a.id} className="p-6 flex items-center justify-between hover:bg-white/5">
                <div>
                  <p className="font-medium text-white">{a.customer_name}</p>
                  <p className="text-white/60 text-sm">
                    {new Date(a.appointment_date).toLocaleTimeString('pt-BR', {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}{' '}
                    • {a.barber.name} • {a.service?.name ?? '-'}
                  </p>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs
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
    </div>
  );
}
