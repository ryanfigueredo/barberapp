'use client';

import { useEffect, useState } from 'react';

interface TenantProfile {
  whatsapp_phone: string | null;
  bot_configured: boolean;
}

export default function WhatsAppPage() {
  const [profile, setProfile] = useState<TenantProfile | null>(null);

  useEffect(() => {
    fetch('/api/admin/tenant-profile', {
      headers: { 'X-API-Key': localStorage.getItem('api_key') || '' },
    })
      .then((r) => r.json())
      .then(setProfile)
      .catch(() => setProfile(null));
  }, []);

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">WhatsApp</h1>
      <p className="text-white/60 mb-8 font-body">Inbox e configuração do bot</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6">
        <h2 className="font-display text-xl text-white mb-4">Status do Bot</h2>
        <div className="space-y-2">
          <p className="text-white/80">
            Telefone: <span className="text-[#F5C518]">{profile?.whatsapp_phone ?? 'Não configurado'}</span>
          </p>
          <p className="text-white/80">
            Bot configurado:{' '}
            <span
              className={
                profile?.bot_configured ? 'text-green-400' : 'text-amber-400'
              }
            >
              {profile?.bot_configured ? 'Sim' : 'Não'}
            </span>
          </p>
        </div>
        <p className="text-white/50 text-sm mt-6">
          Configure o webhook Meta em /api/bot/webhook. Use META_VERIFY_TOKEN para verificação.
        </p>
      </div>

      <div className="mt-8 bg-[#1A1A1A] rounded-xl border border-white/5 p-12 text-center">
        <p className="text-white/50">Inbox de conversas em desenvolvimento</p>
        <p className="text-white/40 text-sm mt-2">
          As mensagens são armazenadas no DynamoDB (BotMessage) e no PostgreSQL
        </p>
      </div>
    </div>
  );
}
