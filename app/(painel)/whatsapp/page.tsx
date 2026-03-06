'use client';

import { useEffect, useState } from 'react';

interface TenantProfile {
  whatsapp_phone: string | null;
  bot_configured: boolean;
}

interface Conversation {
  customer_phone: string;
  last_body: string;
  last_at: string;
  last_direction: string;
  count: number;
}

interface Message {
  id: string;
  direction: string;
  body: string;
  is_bot: boolean;
  created_at: string;
}

function formatPhone(phone: string) {
  const d = phone.replace(/\D/g, '');
  if (d.length >= 10) return `+55 (${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`;
  return phone;
}

function formatDate(iso: string) {
  const d = new Date(iso);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  if (sameDay) return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }) + ' ' + d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}

export default function WhatsAppPage() {
  const [profile, setProfile] = useState<TenantProfile | null>(null);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedPhone, setSelectedPhone] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loadingConv, setLoadingConv] = useState(true);
  const [loadingMsg, setLoadingMsg] = useState(false);

  const apiHeaders = () => ({ 'X-API-Key': typeof localStorage !== 'undefined' ? localStorage.getItem('api_key') || '' : '' });

  useEffect(() => {
    fetch('/api/admin/tenant-profile', { headers: apiHeaders() })
      .then((r) => r.json())
      .then(setProfile)
      .catch(() => setProfile(null));
  }, []);

  useEffect(() => {
    setLoadingConv(true);
    fetch('/api/admin/whatsapp/conversations', { headers: apiHeaders() })
      .then((r) => r.json())
      .then((data) => {
        setConversations(data.conversations || []);
      })
      .catch(() => setConversations([]))
      .finally(() => setLoadingConv(false));
  }, []);

  useEffect(() => {
    if (!selectedPhone) {
      setMessages([]);
      return;
    }
    setLoadingMsg(true);
    fetch(`/api/admin/whatsapp/messages?customer_phone=${encodeURIComponent(selectedPhone)}`, {
      headers: apiHeaders(),
    })
      .then((r) => r.json())
      .then((data) => {
        setMessages(data.messages || []);
      })
      .catch(() => setMessages([]))
      .finally(() => setLoadingMsg(false));
  }, [selectedPhone]);

  const refreshMessages = () => {
    if (!selectedPhone) return;
    fetch(`/api/admin/whatsapp/messages?customer_phone=${encodeURIComponent(selectedPhone)}`, {
      headers: apiHeaders(),
    })
      .then((r) => r.json())
      .then((data) => setMessages(data.messages || []))
      .catch(() => {});
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">WhatsApp</h1>
      <p className="text-white/60 mb-8 font-body">Inbox e configuração do bot — um número para a barbearia, agenda para todos os barbeiros</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6">
        <h2 className="font-display text-xl text-white mb-4">Status do Bot</h2>
        <div className="space-y-2">
          <p className="text-white/80">
            Telefone: <span className="text-[#F5C518]">{profile?.whatsapp_phone ?? 'Não configurado'}</span>
          </p>
          <p className="text-white/80">
            Bot configurado:{' '}
            <span className={profile?.bot_configured ? 'text-green-400' : 'text-amber-400'}>
              {profile?.bot_configured ? 'Sim' : 'Não'}
            </span>
          </p>
        </div>
        <p className="text-white/50 text-sm mt-6">
          Configure o webhook Meta em /api/bot/webhook. O WhatsApp da barbearia é único; os agendamentos podem ser para qualquer barbeiro.
        </p>
      </div>

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden flex flex-col max-h-[500px]">
          <h2 className="font-display text-xl text-white p-4 border-b border-white/5">Conversas</h2>
          <div className="overflow-y-auto flex-1">
            {loadingConv ? (
              <p className="text-white/50 p-4">Carregando...</p>
            ) : conversations.length === 0 ? (
              <p className="text-white/50 p-4">Nenhuma conversa ainda.</p>
            ) : (
              <ul className="divide-y divide-white/5">
                {conversations.map((c) => (
                  <li key={c.customer_phone}>
                    <button
                      type="button"
                      onClick={() => setSelectedPhone(c.customer_phone)}
                      className={`w-full text-left p-4 hover:bg-white/5 transition-colors ${
                        selectedPhone === c.customer_phone ? 'bg-white/10' : ''
                      }`}
                    >
                      <p className="font-medium text-white">{formatPhone(c.customer_phone)}</p>
                      <p className="text-white/60 text-sm truncate mt-0.5">{c.last_body || '—'}</p>
                      <p className="text-white/40 text-xs mt-1">{formatDate(c.last_at)}</p>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        <div className="lg:col-span-2 bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden flex flex-col max-h-[500px]">
          <div className="p-4 border-b border-white/5 flex items-center justify-between">
            <h2 className="font-display text-xl text-white">
              {selectedPhone ? formatPhone(selectedPhone) : 'Selecione uma conversa'}
            </h2>
            {selectedPhone && (
              <button
                type="button"
                onClick={refreshMessages}
                className="text-sm text-[#F5C518] hover:underline"
              >
                Atualizar
              </button>
            )}
          </div>
          <div className="overflow-y-auto flex-1 p-4 space-y-3">
            {!selectedPhone ? (
              <p className="text-white/50">Clique em uma conversa para ver as mensagens.</p>
            ) : loadingMsg ? (
              <p className="text-white/50">Carregando mensagens...</p>
            ) : messages.length === 0 ? (
              <p className="text-white/50">Nenhuma mensagem nesta conversa.</p>
            ) : (
              messages.map((m) => (
                <div
                  key={m.id}
                  className={`flex ${m.direction === 'out' || m.is_bot ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[85%] rounded-lg px-3 py-2 ${
                      m.direction === 'out' || m.is_bot
                        ? 'bg-[#F5C518]/20 text-white'
                        : 'bg-white/10 text-white'
                    }`}
                  >
                    <p className="text-sm whitespace-pre-wrap break-words">{m.body}</p>
                    <p className="text-white/50 text-xs mt-1">{formatDate(m.created_at)}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
