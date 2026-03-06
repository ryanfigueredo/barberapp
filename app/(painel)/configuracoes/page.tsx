'use client';

import { useEffect, useState } from 'react';
import { Eye, EyeOff, Copy, Plus, Pencil, Check, X } from 'lucide-react';

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
  whatsapp_phone: string | null;
}

interface Barber {
  id: string;
  name: string;
  phone: string | null;
  avatar_url: string | null;
  active: boolean;
}

export default function ConfiguracoesPage() {
  const [tenant, setTenant] = useState<Tenant | null>(null);
  const [apiKey, setApiKey] = useState('');
  const [showApiKey, setShowApiKey] = useState(false);

  const [profileForm, setProfileForm] = useState({
    name: '',
    business_name: '',
    address: '',
    opening_time: '09:00',
    closing_time: '20:00',
    slot_duration_minutes: 60,
    whatsapp_phone: '',
  });
  const [savingProfile, setSavingProfile] = useState(false);

  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [barberForm, setBarberForm] = useState({ name: '', phone: '' });
  const [editingBarberId, setEditingBarberId] = useState<string | null>(null);
  const [editBarberForm, setEditBarberForm] = useState({ name: '', phone: '', active: true });
  const [savingBarber, setSavingBarber] = useState(false);
  const [showNewBarber, setShowNewBarber] = useState(false);

  const headers = () => ({
    'X-API-Key': typeof window !== 'undefined' ? localStorage.getItem('api_key') || '' : '',
    'Content-Type': 'application/json',
  });

  useEffect(() => {
    const stored = localStorage.getItem('api_key');
    if (stored) setApiKey(stored);
    fetch('/api/admin/tenant-profile', { headers: { 'X-API-Key': stored || '' } })
      .then((r) => r.json())
      .then((data) => {
        setTenant(data);
        if (data) {
          setProfileForm({
            name: data.name ?? '',
            business_name: data.business_name ?? '',
            address: data.address ?? '',
            opening_time: data.opening_time ?? '09:00',
            closing_time: data.closing_time ?? '20:00',
            slot_duration_minutes: data.slot_duration_minutes ?? 60,
            whatsapp_phone: data.whatsapp_phone ?? '',
          });
        }
      })
      .catch(() => setTenant(null));
  }, []);

  useEffect(() => {
    fetch('/api/admin/barbers', { headers: { 'X-API-Key': localStorage.getItem('api_key') || '' } })
      .then((r) => r.json())
      .then((data) => (Array.isArray(data) ? data : []))
      .then(setBarbers)
      .catch(() => setBarbers([]));
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
      window.prompt('Copie a API Key:', key);
    }
  };

  const saveProfile = async () => {
    setSavingProfile(true);
    try {
      const r = await fetch('/api/admin/tenant-profile', {
        method: 'PATCH',
        headers: headers(),
        body: JSON.stringify({
          name: profileForm.name.trim() || undefined,
          business_name: profileForm.business_name.trim() || undefined,
          address: profileForm.address.trim() || undefined,
          opening_time: profileForm.opening_time || undefined,
          closing_time: profileForm.closing_time || undefined,
          slot_duration_minutes: Number(profileForm.slot_duration_minutes) || 60,
          whatsapp_phone: profileForm.whatsapp_phone.trim() || undefined,
        }),
      });
      if (r.ok) {
        const data = await r.json();
        setTenant((t) => (t ? { ...t, ...data } : null));
        alert('Perfil salvo! As alterações refletem no app.');
      }
    } finally {
      setSavingProfile(false);
    }
  };

  const createBarber = async () => {
    if (!barberForm.name.trim()) return;
    setSavingBarber(true);
    try {
      const r = await fetch('/api/admin/barbers', {
        method: 'POST',
        headers: headers(),
        body: JSON.stringify({
          name: barberForm.name.trim(),
          phone: barberForm.phone.trim() || null,
        }),
      });
      if (r.ok) {
        const newBarber = await r.json();
        setBarbers((prev) => [...prev, newBarber]);
        setBarberForm({ name: '', phone: '' });
        setShowNewBarber(false);
      } else {
        const err = await r.json();
        alert(err.error || 'Erro ao criar barbeiro');
      }
    } finally {
      setSavingBarber(false);
    }
  };

  const startEditBarber = (b: Barber) => {
    setEditingBarberId(b.id);
    setEditBarberForm({
      name: b.name,
      phone: b.phone ?? '',
      active: b.active,
    });
    setShowNewBarber(false);
  };

  const saveBarber = async () => {
    if (!editingBarberId) return;
    setSavingBarber(true);
    try {
      const r = await fetch(`/api/admin/barbers/${editingBarberId}`, {
        method: 'PATCH',
        headers: headers(),
        body: JSON.stringify({
          name: editBarberForm.name.trim(),
          phone: editBarberForm.phone.trim() || null,
          active: editBarberForm.active,
        }),
      });
      if (r.ok) {
        const updated = await r.json();
        setBarbers((prev) => prev.map((x) => (x.id === editingBarberId ? updated : x)));
        setEditingBarberId(null);
      }
    } finally {
      setSavingBarber(false);
    }
  };

  const desativarBarber = async (id: string) => {
    if (!confirm('Desativar este barbeiro?')) return;
    const r = await fetch(`/api/admin/barbers/${id}`, {
      method: 'DELETE',
      headers: { 'X-API-Key': typeof window !== 'undefined' ? localStorage.getItem('api_key') || '' : '' },
    });
    if (r.ok) {
      setBarbers((prev) => prev.map((x) => (x.id === id ? { ...x, active: false } : x)));
      setEditingBarberId(null);
    }
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#D9AE59] mb-2">Configurações</h1>
      <p className="text-white/60 mb-8 font-body">Perfil da barbearia, barbeiros e acesso. Cada barbeiro tem seu login; o WhatsApp é um só e agenda para todos.</p>

      <div className="space-y-8 max-w-3xl">
        {/* API Key */}
        <div className="bg-[#1C1C1E] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">API Key (acesso ao painel)</h2>
          <p className="text-white/60 text-sm mb-4">
            Use a api_key do tenant para autenticar. O dono (ex.: ryan@dmtn.com.br) e cada barbeiro têm seu próprio acesso.
          </p>
          <div className="flex gap-3 flex-wrap">
            <input
              type={showApiKey ? 'text' : 'password'}
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              placeholder="Cole sua API Key aqui"
              className="flex-1 min-w-[200px] px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-white/40 focus:outline-none focus:border-[#D9AE59]"
            />
            <button
              type="button"
              onClick={() => setShowApiKey((v) => !v)}
              className="p-3 bg-white/5 border border-white/10 rounded-lg text-white/80 hover:text-white"
              aria-label={showApiKey ? 'Ocultar' : 'Mostrar'}
            >
              {showApiKey ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
            <button
              type="button"
              onClick={copyApiKey}
              disabled={!apiKey.trim()}
              className="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white/80 hover:text-white disabled:opacity-40 flex items-center gap-2"
            >
              <Copy className="w-4 h-4" />
              Copiar
            </button>
            <button
              onClick={saveApiKey}
              className="px-6 py-3 bg-[#D9AE59] text-black font-semibold rounded-lg hover:opacity-90 transition"
            >
              Salvar
            </button>
          </div>
        </div>

        {/* Perfil da barbearia (editável) */}
        <div className="bg-[#1C1C1E] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">Perfil da barbearia</h2>
          <p className="text-white/60 text-sm mb-4">Alterações refletem no app (nome, horário, WhatsApp, etc.).</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-white/60 text-sm mb-1">Nome interno</label>
              <input
                value={profileForm.name}
                onChange={(e) => setProfileForm((f) => ({ ...f, name: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                placeholder="Nome"
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">Nome comercial (app)</label>
              <input
                value={profileForm.business_name}
                onChange={(e) => setProfileForm((f) => ({ ...f, business_name: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                placeholder="Barbearia do Zé"
              />
            </div>
            <div className="sm:col-span-2">
              <label className="block text-white/60 text-sm mb-1">Endereço</label>
              <input
                value={profileForm.address}
                onChange={(e) => setProfileForm((f) => ({ ...f, address: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                placeholder="Rua, número, bairro"
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">Abertura</label>
              <input
                type="time"
                value={profileForm.opening_time}
                onChange={(e) => setProfileForm((f) => ({ ...f, opening_time: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">Fechamento</label>
              <input
                type="time"
                value={profileForm.closing_time}
                onChange={(e) => setProfileForm((f) => ({ ...f, closing_time: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">Duração do slot (min)</label>
              <input
                type="number"
                min={15}
                max={120}
                value={profileForm.slot_duration_minutes}
                onChange={(e) => setProfileForm((f) => ({ ...f, slot_duration_minutes: Number(e.target.value) || 60 }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">WhatsApp (barbearia)</label>
              <input
                value={profileForm.whatsapp_phone}
                onChange={(e) => setProfileForm((f) => ({ ...f, whatsapp_phone: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                placeholder="5521999999999"
              />
              <p className="text-white/40 text-xs mt-1">Um número para a barbearia; o bot agenda para todos os barbeiros.</p>
            </div>
          </div>
          <button
            onClick={saveProfile}
            disabled={savingProfile}
            className="px-6 py-3 bg-[#D9AE59] text-black font-semibold rounded-lg hover:opacity-90 transition disabled:opacity-50"
          >
            {savingProfile ? 'Salvando...' : 'Salvar perfil'}
          </button>
        </div>

        {/* Barbeiros */}
        <div className="bg-[#1C1C1E] rounded-xl border border-white/5 p-6">
          <h2 className="font-display text-xl text-white mb-4">Barbeiros</h2>
          <p className="text-white/60 text-sm mb-4">Cada barbeiro pode ter acesso próprio ao app. Crie e edite aqui.</p>

          {!showNewBarber ? (
            <button
              onClick={() => setShowNewBarber(true)}
              className="mb-4 inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#D9AE59] text-black font-medium hover:opacity-90 transition"
            >
              <Plus className="w-4 h-4" />
              Novo barbeiro
            </button>
          ) : (
            <div className="mb-6 p-4 bg-white/5 rounded-lg border border-white/10">
              <h3 className="font-display text-[#D9AE59] mb-3">Novo barbeiro</h3>
              <div className="flex flex-wrap gap-4 items-end">
                <div>
                  <label className="block text-white/60 text-sm mb-1">Nome</label>
                  <input
                    value={barberForm.name}
                    onChange={(e) => setBarberForm((f) => ({ ...f, name: e.target.value }))}
                    className="w-48 px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                    placeholder="Nome do barbeiro"
                  />
                </div>
                <div>
                  <label className="block text-white/60 text-sm mb-1">Telefone (opcional)</label>
                  <input
                    value={barberForm.phone}
                    onChange={(e) => setBarberForm((f) => ({ ...f, phone: e.target.value }))}
                    className="w-40 px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                    placeholder="21999999999"
                  />
                </div>
                <button
                  onClick={createBarber}
                  disabled={savingBarber || !barberForm.name.trim()}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#D9AE59] text-black font-medium hover:opacity-90 disabled:opacity-50"
                >
                  <Check className="w-4 h-4" />
                  Salvar
                </button>
                <button
                  onClick={() => { setShowNewBarber(false); setBarberForm({ name: '', phone: '' }); }}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-white/20 text-white hover:bg-white/5"
                >
                  <X className="w-4 h-4" />
                  Cancelar
                </button>
              </div>
            </div>
          )}

          <div className="divide-y divide-white/5">
            {barbers.length === 0 && !showNewBarber ? (
              <p className="text-white/50 py-4">Nenhum barbeiro cadastrado. Adicione o primeiro acima.</p>
            ) : (
              barbers.map((b) => (
                <div key={b.id} className="py-4 flex flex-wrap items-center justify-between gap-4">
                  {editingBarberId === b.id ? (
                    <>
                      <div className="flex flex-wrap gap-4 items-end">
                        <div>
                          <label className="block text-white/60 text-sm mb-1">Nome</label>
                          <input
                            value={editBarberForm.name}
                            onChange={(e) => setEditBarberForm((f) => ({ ...f, name: e.target.value }))}
                            className="w-48 px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                          />
                        </div>
                        <div>
                          <label className="block text-white/60 text-sm mb-1">Telefone</label>
                          <input
                            value={editBarberForm.phone}
                            onChange={(e) => setEditBarberForm((f) => ({ ...f, phone: e.target.value }))}
                            className="w-40 px-3 py-2 rounded-lg bg-[#141416] border border-white/10 text-white"
                          />
                        </div>
                        <label className="flex items-center gap-2 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={editBarberForm.active}
                            onChange={(e) => setEditBarberForm((f) => ({ ...f, active: e.target.checked }))}
                            className="rounded border-white/20"
                          />
                          <span className="text-white/80 text-sm">Ativo</span>
                        </label>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={saveBarber}
                          disabled={savingBarber}
                          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#D9AE59] text-black font-medium disabled:opacity-50"
                        >
                          <Check className="w-4 h-4" />
                          Salvar
                        </button>
                        <button
                          onClick={() => setEditingBarberId(null)}
                          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-white/20 text-white hover:bg-white/5"
                        >
                          <X className="w-4 h-4" />
                          Cancelar
                        </button>
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center font-display text-[#D9AE59]">
                          {b.name.charAt(0)}
                        </div>
                        <div>
                          <p className="font-medium text-white">{b.name}</p>
                          <p className="text-white/60 text-sm">{b.phone ?? 'Sem telefone'}</p>
                        </div>
                        <span className={`px-2 py-0.5 rounded text-xs ${b.active ? 'bg-green-500/20 text-green-400' : 'bg-white/10 text-white/50'}`}>
                          {b.active ? 'Ativo' : 'Inativo'}
                        </span>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => startEditBarber(b)}
                          className="p-2 rounded-lg text-white/70 hover:text-white hover:bg-white/10"
                          aria-label="Editar"
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        {b.active && (
                          <button
                            onClick={() => desativarBarber(b.id)}
                            className="text-sm text-white/50 hover:text-red-400"
                          >
                            Desativar
                          </button>
                        )}
                      </div>
                    </>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
