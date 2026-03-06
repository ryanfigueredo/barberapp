'use client';

import { useEffect, useState } from 'react';

interface Barber {
  id: string;
  name: string;
  phone: string | null;
  avatar_url: string | null;
  active: boolean;
}

export default function BarbeirosPage() {
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/barbers', {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then(async (r) => {
        const data = await r.json();
        return r.ok && Array.isArray(data) ? data : [];
      })
      .then(setBarbers)
      .catch(() => setBarbers([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Barbeiros</h1>
      <p className="text-white/60 mb-8 font-body">Gerencie os barbeiros da barbearia</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-white/60">Carregando...</div>
        ) : barbers.length === 0 ? (
          <div className="p-12 text-center text-white/50">Nenhum barbeiro cadastrado</div>
        ) : (
          <div className="divide-y divide-white/5">
            {barbers.map((b) => (
              <div
                key={b.id}
                className="p-6 flex items-center justify-between hover:bg-white/5 transition"
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center font-display text-lg text-[#F5C518]">
                    {b.name.charAt(0)}
                  </div>
                  <div>
                    <p className="font-medium text-white">{b.name}</p>
                    <p className="text-white/60 text-sm">{b.phone ?? 'Sem telefone'}</p>
                  </div>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs ${
                    b.active ? 'bg-green-500/20 text-green-400' : 'bg-white/10 text-white/50'
                  }`}
                >
                  {b.active ? 'Ativo' : 'Inativo'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
