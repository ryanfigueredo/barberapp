'use client';

import { useEffect, useState } from 'react';
import { Pencil, Plus, Check, X } from 'lucide-react';

interface Service {
  id: string;
  name: string;
  price: number;
  duration_minutes: number;
  active: boolean;
}

export default function ServicosPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState({ name: '', price: '', duration_minutes: '', active: true });
  const [saving, setSaving] = useState(false);
  const [showNew, setShowNew] = useState(false);

  const apiKey = typeof window !== 'undefined' ? localStorage.getItem('api_key') || '' : '';
  const headers = { 'X-API-Key': apiKey, 'Content-Type': 'application/json' };

  const loadServices = () => {
    fetch('/api/admin/services', { headers: { 'X-API-Key': apiKey } })
      .then(async (r) => {
        const data = await r.json();
        return r.ok && Array.isArray(data) ? data : [];
      })
      .then(setServices)
      .catch(() => setServices([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadServices();
  }, []);

  const startEdit = (s: Service) => {
    setEditingId(s.id);
    setForm({
      name: s.name,
      price: String(s.price),
      duration_minutes: String(s.duration_minutes),
      active: s.active,
    });
    setShowNew(false);
  };

  const cancelEdit = () => {
    setEditingId(null);
    setForm({ name: '', price: '', duration_minutes: '', active: true });
  };

  const saveEdit = async () => {
    if (!editingId) return;
    setSaving(true);
    try {
      const r = await fetch(`/api/admin/services/${editingId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({
          name: form.name.trim(),
          price: Number(form.price) || 0,
          duration_minutes: Number(form.duration_minutes) || 60,
          active: form.active,
        }),
      });
      if (r.ok) {
        await loadServices();
        cancelEdit();
      }
    } finally {
      setSaving(false);
    }
  };

  const createService = async () => {
    if (!form.name.trim()) return;
    setSaving(true);
    try {
      const r = await fetch('/api/admin/services', {
        method: 'POST',
        headers,
        body: JSON.stringify({
          name: form.name.trim(),
          price: Number(form.price) || 0,
          duration_minutes: Number(form.duration_minutes) || 60,
        }),
      });
      if (r.ok) {
        await loadServices();
        setForm({ name: '', price: '', duration_minutes: '60', active: true });
        setShowNew(false);
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-8">
      <h1 className="font-display text-3xl text-[#F5C518] mb-2">Serviços</h1>
      <p className="text-white/60 mb-8 font-body">Preços e duração — alterações refletem no app e no bot</p>

      <div className="flex justify-end mb-6">
        <button
          onClick={() => {
            setShowNew(true);
            setForm({ name: '', price: '', duration_minutes: '60', active: true });
            setEditingId(null);
          }}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 transition"
        >
          <Plus className="w-4 h-4" />
          Novo serviço
        </button>
      </div>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-white/60">Carregando...</div>
        ) : services.length === 0 && !showNew ? (
          <div className="p-12 text-center text-white/50">Nenhum serviço cadastrado</div>
        ) : (
          <div className="divide-y divide-white/5">
            {showNew && (
              <div className="p-6 bg-white/5 border-b border-white/10">
                <h3 className="font-display text-[#F5C518] mb-4">Novo serviço</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                  <div>
                    <label className="block text-white/60 text-sm mb-1">Nome</label>
                    <input
                      value={form.name}
                      onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                      className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                      placeholder="Ex: Corte + Barba"
                    />
                  </div>
                  <div>
                    <label className="block text-white/60 text-sm mb-1">Preço (R$)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={form.price}
                      onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))}
                      className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                      placeholder="0,00"
                    />
                  </div>
                  <div>
                    <label className="block text-white/60 text-sm mb-1">Duração (min)</label>
                    <input
                      type="number"
                      value={form.duration_minutes}
                      onChange={(e) => setForm((f) => ({ ...f, duration_minutes: e.target.value }))}
                      className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                      placeholder="60"
                    />
                  </div>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={createService}
                    disabled={saving || !form.name.trim()}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 disabled:opacity-50"
                  >
                    <Check className="w-4 h-4" />
                    Salvar
                  </button>
                  <button
                    onClick={() => setShowNew(false)}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-white/20 text-white hover:bg-white/5"
                  >
                    <X className="w-4 h-4" />
                    Cancelar
                  </button>
                </div>
              </div>
            )}
            {services.map((s) => (
              <div
                key={s.id}
                className="p-6 flex flex-wrap items-center justify-between gap-4 hover:bg-white/5 transition"
              >
                {editingId === s.id ? (
                  <>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 flex-1 min-w-0">
                      <div>
                        <label className="block text-white/60 text-sm mb-1">Nome</label>
                        <input
                          value={form.name}
                          onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                          className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                        />
                      </div>
                      <div>
                        <label className="block text-white/60 text-sm mb-1">Preço (R$)</label>
                        <input
                          type="number"
                          step="0.01"
                          value={form.price}
                          onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))}
                          className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                        />
                      </div>
                      <div>
                        <label className="block text-white/60 text-sm mb-1">Duração (min)</label>
                        <input
                          type="number"
                          value={form.duration_minutes}
                          onChange={(e) => setForm((f) => ({ ...f, duration_minutes: e.target.value }))}
                          className="w-full px-3 py-2 rounded-lg bg-[#0A0A0A] border border-white/10 text-white"
                        />
                      </div>
                      <div className="flex items-end gap-2">
                        <label className="flex items-center gap-2 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={form.active}
                            onChange={(e) => setForm((f) => ({ ...f, active: e.target.checked }))}
                            className="rounded border-white/20"
                          />
                          <span className="text-white/80 text-sm">Ativo</span>
                        </label>
                      </div>
                    </div>
                    <div className="flex gap-2 shrink-0">
                      <button
                        onClick={saveEdit}
                        disabled={saving}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#F5C518] text-black font-medium hover:bg-amber-400 disabled:opacity-50"
                      >
                        <Check className="w-4 h-4" />
                        Salvar
                      </button>
                      <button
                        onClick={cancelEdit}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-white/20 text-white hover:bg-white/5"
                      >
                        <X className="w-4 h-4" />
                        Cancelar
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <div>
                      <p className="font-medium text-white">{s.name}</p>
                      <p className="text-white/60 text-sm">{s.duration_minutes} min</p>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className="font-display text-xl text-[#F5C518]">
                        R$ {Number(s.price).toFixed(2)}
                      </span>
                      <span
                        className={`px-3 py-1 rounded-full text-xs ${
                          s.active ? 'bg-green-500/20 text-green-400' : 'bg-white/10 text-white/50'
                        }`}
                      >
                        {s.active ? 'Ativo' : 'Inativo'}
                      </span>
                      <button
                        onClick={() => startEdit(s)}
                        className="p-2 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition"
                        aria-label="Editar"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                    </div>
                  </>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
