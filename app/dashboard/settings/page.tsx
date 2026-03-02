'use client';

import { useEffect, useState } from 'react';
import { Eye, EyeOff, Copy } from 'lucide-react';

interface Tenant {
  id: string;
  name: string;
  slug: string;
  business_name: string | null;
  logo_url: string | null;
  address: string | null;
  opening_time: string | null;
  closing_time: string | null;
  slot_duration_minutes: number;
}

export default function SettingsPage() {
  const [tenant, setTenant] = useState<Tenant | null>(null);
  const [apiKey, setApiKey] = useState('');
  const [showApiKey, setShowApiKey] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem('api_key');
    if (stored) setApiKey(stored);
    fetch('/api/admin/tenant-profile', {
      headers: { 'X-API-Key': stored || '' },
    })
      .then((r) => r.json())
      .then(setTenant)
      .catch(() => setTenant(null));
  }, []);

  const saveApiKey = () => {
    if (apiKey.trim()) {
      localStorage.setItem('api_key', apiKey.trim());
      alert('API Key salva! Recarregue a página.');
    }
  };

  const copyApiKey = async () => {
    const key = apiKey.trim();
    if (!key) return;
    try {
      await navigator.clipboard.writeText(key);
      alert('API Key copiada!');
    } catch {
      // Fallback simples
      window.prompt('Copie a API Key:', key);
    }
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Configurações</h1>
      <p className="text-white/60 mb-8 font-body">Perfil da barbearia</p>

      <div className="space-y-8 max-w-2xl">
        <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">API Key (para dashboard)</h2>
          <p className="text-white/60 text-sm mb-4">
            Use a api_key do tenant para autenticar as requisições do dashboard.
          </p>
          <div className="flex gap-3">
            <input
              type={showApiKey ? 'text' : 'password'}
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              placeholder="Cole sua API Key aqui"
              className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/40 focus:outline-none focus:border-[#F5C518]"
            />
            <button
              type="button"
              onClick={() => setShowApiKey((v) => !v)}
              className="p-3 bg-white/5 border border-white/10 rounded-lg text-white/80 hover:text-white hover:border-white/20 transition flex items-center justify-center"
              aria-label={showApiKey ? 'Ocultar API Key' : 'Mostrar API Key'}
              title={showApiKey ? 'Ocultar' : 'Mostrar'}
            >
              {showApiKey ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
            <button
              type="button"
              onClick={copyApiKey}
              disabled={!apiKey.trim()}
              className="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white/80 hover:text-white hover:border-white/20 disabled:opacity-40 disabled:cursor-not-allowed transition flex items-center gap-2"
              title="Copiar API Key"
            >
              <Copy className="w-4 h-4" />
              Copiar
            </button>
            <button
              onClick={saveApiKey}
              className="px-6 py-3 bg-[#F5C518] text-black font-semibold rounded-lg hover:bg-amber-400 transition"
            >
              Salvar
            </button>
          </div>
        </div>

        {tenant && (
          <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6">
            <h2 className="font-display text-xl text-white mb-4">Perfil</h2>
            <dl className="space-y-3 text-white/80">
              <div>
                <dt className="text-white/50 text-sm">Nome</dt>
                <dd>{tenant.name}</dd>
              </div>
              <div>
                <dt className="text-white/50 text-sm">Slug</dt>
                <dd>{tenant.slug}</dd>
              </div>
              <div>
                <dt className="text-white/50 text-sm">Nome comercial</dt>
                <dd>{tenant.business_name ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-white/50 text-sm">Endereço</dt>
                <dd>{tenant.address ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-white/50 text-sm">Horário</dt>
                <dd>
                  {tenant.opening_time ?? '09:00'} - {tenant.closing_time ?? '20:00'}
                </dd>
              </div>
              <div>
                <dt className="text-white/50 text-sm">Duração do slot (min)</dt>
                <dd>{tenant.slot_duration_minutes}</dd>
              </div>
            </dl>
          </div>
        )}
      </div>
    </div>
  );
}
