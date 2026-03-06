'use client';

import { useEffect, useState } from 'react';

interface Barber {
  id: string;
  name: string;
}

export default function SlotsPage() {
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [generating, setGenerating] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  const startDate = new Date();
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + 6);

  useEffect(() => {
    fetch('/api/app/barbers', {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then(async (r) => {
        const data = await r.json();
        return r.ok && Array.isArray(data) ? data : [];
      })
      .then(setBarbers)
      .catch(() => setBarbers([]));
  }, []);

  const handleGenerate = (barberId: string) => {
    setGenerating(true);
    setResult(null);
    fetch('/api/admin/slots/generate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': localStorage.getItem('api_key') || '',
      },
      body: JSON.stringify({
        barber_id: barberId,
        start_date: startDate.toISOString().slice(0, 10),
        end_date: endDate.toISOString().slice(0, 10),
        daily_start: '09:00',
        daily_end: '20:00',
        slot_duration_minutes: 60,
        break_times: [{ start: '12:00', end: '13:00' }],
        days_of_week: [1, 2, 3, 4, 5, 6],
      }),
    })
      .then((r) => r.json())
      .then((d) =>
        setResult(d.created ? `✅ ${d.created} slots criados` : d.error || 'Erro')
      )
      .catch(() => setResult('Erro ao gerar slots'))
      .finally(() => setGenerating(false));
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Slots</h1>
      <p className="text-white/60 mb-8 font-body">Gere agenda semanal para os barbeiros</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-8">
        <h2 className="font-display text-xl text-white mb-4">Gerar slots da semana</h2>
        <p className="text-white/60 text-sm mb-6">
          Período: {startDate.toLocaleDateString('pt-BR')} a {endDate.toLocaleDateString('pt-BR')}
          <br />
          Horário: 09:00 - 20:00 (pausa 12h-13h) • Seg-Sáb
        </p>
        <div className="flex flex-wrap gap-4">
          {barbers.map((b) => (
            <button
              key={b.id}
              onClick={() => handleGenerate(b.id)}
              disabled={generating}
              className="px-6 py-3 bg-[#F5C518] text-black font-semibold rounded-lg hover:bg-amber-400 transition disabled:opacity-50"
            >
              Gerar para {b.name}
            </button>
          ))}
        </div>
        {result && <p className="mt-4 text-white/80">{result}</p>}
      </div>
    </div>
  );
}
