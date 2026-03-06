'use client';

import { useEffect, useState } from 'react';

interface Barber {
  id: string;
  name: string;
  phone: string | null;
  avatar_url: string | null;
  active: boolean;
}

interface Connection {
  id: string;
  barber_id: string | null;
  barber: { id: string; name: string } | null;
  whatsapp_phone: string | null;
  meta_phone_number_id: string;
  bot_configured: boolean;
  created_at: string;
}

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
  const [connections, setConnections] = useState<Connection[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedPhone, setSelectedPhone] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loadingConv, setLoadingConv] = useState(true);
  const [loadingMsg, setLoadingMsg] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [addForm, setAddForm] = useState({
    barber_id: '',
    whatsapp_phone: '',
    meta_phone_number_id: '',
    meta_access_token: '',
  });
  const [savingConnection, setSavingConnection] = useState(false);
  const [addError, setAddError] = useState('');

  const apiHeaders = () => ({ 'X-API-Key': typeof localStorage !== 'undefined' ? localStorage.getItem('api_key') || '' : '' });

  useEffect(() => {
    fetch('/api/admin/tenant-profile', { headers: apiHeaders() })
      .then((r) => r.json())
      .then(setProfile)
      .catch(() => setProfile(null));
  }, []);

  useEffect(() => {
    fetch('/api/admin/whatsapp/connections', { headers: apiHeaders() })
      .then((r) => r.json())
      .then((data) => setConnections(data.connections || []))
      .catch(() => setConnections([]));
  }, []);

  useEffect(() => {
    fetch('/api/admin/barbers', { headers: apiHeaders() })
      .then((r) => r.json())
      .then((data) => (Array.isArray(data) ? data : []))
      .then(setBarbers)
      .catch(() => setBarbers([]));
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

  const saveConnection = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddError('');
    setSavingConnection(true);
    try {
      const r = await fetch('/api/admin/whatsapp/connections', {
        method: 'POST',
        headers: { ...apiHeaders(), 'Content-Type': 'application/json' },
        body: JSON.stringify({
          barber_id: addForm.barber_id || undefined,
          whatsapp_phone: addForm.whatsapp_phone.trim() || undefined,
          meta_phone_number_id: addForm.meta_phone_number_id.trim(),
          meta_access_token: addForm.meta_access_token.trim(),
        }),
      });
      const data = await r.json();
      if (!r.ok) {
        setAddError(data.error || 'Erro ao salvar');
        return;
      }
      setConnections((prev) => [...prev, data]);
      setAddForm({ barber_id: '', whatsapp_phone: '', meta_phone_number_id: '', meta_access_token: '' });
      setShowAddForm(false);
    } catch {
      setAddError('Erro de conexão');
    } finally {
      setSavingConnection(false);
    }
  };

  const removeConnection = async (id: string) => {
    if (!confirm('Remover este número? O bot deixará de responder por ele.')) return;
    try {
      await fetch(`/api/admin/whatsapp/connections/${id}`, { method: 'DELETE', headers: apiHeaders() });
      setConnections((prev) => prev.filter((c) => c.id !== id));
    } catch {}
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">WhatsApp</h1>
      <p className="text-white/60 mb-8 font-body">Um número geral ou um por barbeiro — você escolhe</p>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-6">
        <h2 className="font-display text-xl text-white mb-4">Números WhatsApp</h2>
        {connections.length === 0 && !showAddForm ? (
          <p className="text-white/50 mb-4">Nenhum número configurado. Adicione um número geral da barbearia ou um por barbeiro.</p>
        ) : (
          <ul className="space-y-3 mb-4">
            {connections.map((c) => (
              <li key={c.id} className="flex items-center justify-between py-2 border-b border-white/5 last:border-0">
                <div>
                  <span className="text-[#F5C518] font-medium">
                    {c.barber ? c.barber.name : 'Geral (barbearia)'}
                  </span>
                  <span className="text-white/60 text-sm ml-2">
                    {c.whatsapp_phone || c.meta_phone_number_id}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => removeConnection(c.id)}
                  className="text-red-400 hover:text-red-300 text-sm"
                >
                  Remover
                </button>
              </li>
            ))}
          </ul>
        )}
        {!showAddForm ? (
          <button
            type="button"
            onClick={() => setShowAddForm(true)}
            className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
          >
            Adicionar número
          </button>
        ) : (
          <form onSubmit={saveConnection} className="space-y-3 pt-2">
            {addError && <p className="text-red-400 text-sm">{addError}</p>}
            <div>
              <label className="block text-white/70 text-sm mb-1">Vincular a barbeiro (opcional)</label>
              <select
                value={addForm.barber_id}
                onChange={(e) => setAddForm((f) => ({ ...f, barber_id: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-white/5 border border-white/10 text-white"
              >
                <option value="">Geral (toda a barbearia)</option>
                {barbers.map((b) => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-white/70 text-sm mb-1">Telefone (exibição)</label>
              <input
                type="text"
                value={addForm.whatsapp_phone}
                onChange={(e) => setAddForm((f) => ({ ...f, whatsapp_phone: e.target.value }))}
                placeholder="+55 11 99999-9999"
                className="w-full px-3 py-2 rounded-lg bg-white/5 border border-white/10 text-white placeholder-white/40"
              />
            </div>
            <div>
              <label className="block text-white/70 text-sm mb-1">Meta Phone Number ID *</label>
              <input
                type="text"
                value={addForm.meta_phone_number_id}
                onChange={(e) => setAddForm((f) => ({ ...f, meta_phone_number_id: e.target.value }))}
                required
                placeholder="Ex: 983471751512371 (ID do número, não o ID da conta)"
                className="w-full px-3 py-2 rounded-lg bg-white/5 border border-white/10 text-white placeholder-white/40"
              />
              <p className="text-white/45 text-xs mt-1">Use a &quot;Identificação do número de telefone&quot; do Meta (não o ID da conta/WABA).</p>
            </div>
            <div>
              <label className="block text-white/70 text-sm mb-1">Meta Access Token *</label>
              <input
                type="password"
                value={addForm.meta_access_token}
                onChange={(e) => setAddForm((f) => ({ ...f, meta_access_token: e.target.value }))}
                required
                placeholder="Token da API WhatsApp"
                className="w-full px-3 py-2 rounded-lg bg-white/5 border border-white/10 text-white placeholder-white/40"
              />
            </div>
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={savingConnection}
                className="px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition disabled:opacity-50"
              >
                {savingConnection ? 'Salvando...' : 'Salvar'}
              </button>
              <button
                type="button"
                onClick={() => { setShowAddForm(false); setAddError(''); }}
                className="px-4 py-2 rounded-lg bg-white/10 text-white hover:bg-white/20 transition"
              >
                Cancelar
              </button>
            </div>
          </form>
        )}
        <p className="text-white/50 text-sm mt-6">
          Webhook Meta: /api/bot/webhook. Cada número pode ser geral (toda a barbearia) ou vinculado a um barbeiro.
        </p>
      </div>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-6">
        <h2 className="font-display text-xl text-white mb-4">Status do Bot</h2>
        <div className="space-y-2">
          <p className="text-white/80">
            Números ativos: <span className="text-[#F5C518]">{connections.length}</span>
          </p>
          <p className="text-white/80">
            Bot configurado:{' '}
            <span className={connections.length > 0 ? 'text-green-400' : 'text-amber-400'}>
              {connections.length > 0 ? 'Sim' : 'Não'}
            </span>
          </p>
        </div>
        <p className="text-white/50 text-sm mt-6">
          Configure o webhook Meta em /api/bot/webhook.
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
