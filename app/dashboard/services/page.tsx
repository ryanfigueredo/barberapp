'use client';

import { useEffect, useState } from 'react';

interface Service {
  id: string;
  name: string;
  price: number;
  duration_minutes: number;
  active: boolean;
}

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/services', {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then(async (r) => {
        const data = await r.json();
        return r.ok && Array.isArray(data) ? data : [];
      })
      .then(setServices)
      .catch(() => setServices([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Serviços</h1>
      <p className="text-white/60 mb-8 font-body">Preços e duração dos serviços</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-white/60">Carregando...</div>
        ) : services.length === 0 ? (
          <div className="p-12 text-center text-white/50">Nenhum serviço cadastrado</div>
        ) : (
          <div className="divide-y divide-white/5">
            {services.map((s) => (
              <div
                key={s.id}
                className="p-6 flex items-center justify-between hover:bg-white/5 transition"
              >
                <div>
                  <p className="font-medium text-white">{s.name}</p>
                  <p className="text-white/60 text-sm">{s.duration_minutes} minutos</p>
                </div>
                <div className="flex items-center gap-4">
                  <span className="font-display text-xl text-[#F5C518]">
                    R$ {s.price.toFixed(2)}
                  </span>
                  <span
                    className={`px-3 py-1 rounded-full text-xs ${
                      s.active ? 'bg-green-500/20 text-green-400' : 'bg-white/10 text-white/50'
                    }`}
                  >
                    {s.active ? 'Ativo' : 'Inativo'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
