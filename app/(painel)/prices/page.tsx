'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface MeResponse {
  user?: {
    id: string;
    username: string;
    name: string;
    role: string;
    tenant_id: string | null;
    barber_id: string | null;
  } | null;
  tenant?: { id: string; name: string };
}

const ALLOWED_EMAIL = 'ryan@dmtn.com.br';

export default function PricesPage() {
  const router = useRouter();
  const [allowed, setAllowed] = useState<boolean | null>(null);

  useEffect(() => {
    const apiKey = typeof window !== 'undefined' ? localStorage.getItem('api_key') : null;
    if (!apiKey) {
      router.replace('/login');
      return;
    }

    fetch('/api/me', {
      credentials: 'include',
      headers: { 'X-API-Key': apiKey },
    })
      .then((r) => r.json())
      .then((data: MeResponse) => {
        const username = data.user?.username ?? '';
        setAllowed(username === ALLOWED_EMAIL);
        if (username && username !== ALLOWED_EMAIL) {
          router.replace('/inicio');
        }
      })
      .catch(() => setAllowed(false));
  }, [router]);

  if (allowed === null) {
    return (
      <div className="p-8">
        <p className="text-white/60">Verificando acesso...</p>
      </div>
    );
  }

  if (!allowed) {
    return (
      <div className="p-8">
        <p className="text-white/60">Acesso negado.</p>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[var(--barber-gold)] mb-2">Preços</h1>
      <p className="text-white/60 mb-8 font-body">Valores e faixas do BarberApp (acesso restrito)</p>

      <div className="max-w-2xl space-y-6">
        <div className="bg-[var(--barber-surface-high)] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">Assinatura mensal</h2>
          <ul className="space-y-3 text-white/80">
            <li>
              <strong className="text-[var(--barber-gold)]">Base (1 a 3 barbeiros):</strong> R$ 129/mês
            </li>
            <li>
              <strong className="text-[var(--barber-gold)]">A partir do 4º barbeiro:</strong> + R$ 39 por barbeiro/mês
            </li>
            <li>Ex.: 4 barbeiros = R$ 168/mês · 5 barbeiros = R$ 207/mês</li>
          </ul>
        </div>

        <div className="bg-[var(--barber-surface-high)] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">Configuração inicial</h2>
          <ul className="space-y-3 text-white/80">
            <li>
              <strong className="text-[var(--barber-gold)]">Taxa única (opcional):</strong> R$ 199 ou R$ 249
            </li>
            <li>Inclui: conta, horários, serviços, barbeiros e (se contratado) configuração do WhatsApp</li>
          </ul>
        </div>

        <div className="bg-[var(--barber-surface-high)] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">WhatsApp</h2>
          <ul className="space-y-3 text-white/80">
            <li><strong className="text-[var(--barber-gold)]">Um número (geral):</strong> todos os barbeiros no mesmo WhatsApp</li>
            <li><strong className="text-[var(--barber-gold)]">Número por barbeiro:</strong> cada barbeiro com seu próprio número (mesma barbearia)</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
