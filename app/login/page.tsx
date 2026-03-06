'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || 'Erro ao fazer login');
        return;
      }
      if (data.api_key) {
        localStorage.setItem('api_key', data.api_key);
      }
      if (data.user) {
        localStorage.setItem('user_role', data.user.role);
        localStorage.setItem('user_barber_name', data.user.barber?.name ?? '');
      }
      router.push('/inicio');
    } catch {
      setError('Erro de conexão');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6" style={{ backgroundColor: 'var(--barber-bg)' }}>
      <div className="w-full max-w-md">
        <h1 className="font-display text-3xl text-center mb-2" style={{ color: 'var(--barber-gold)' }}>
          BarberApp
        </h1>
        <p className="text-center mb-8 font-body" style={{ color: 'var(--barber-text-secondary)' }}>
          Faça login para acessar o dashboard
        </p>
        <form
          onSubmit={handleSubmit}
          className="rounded-xl border border-white/5 p-8"
          style={{ backgroundColor: 'var(--barber-surface-high)' }}
        >
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-500/20 text-red-400 text-sm">
              {error}
            </div>
          )}
          <div className="space-y-4">
            <div>
              <label className="block text-white/80 text-sm mb-2">Usuário</label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                className="w-full px-4 py-3 border border-white/10 rounded-lg text-white placeholder-white/40 focus:outline-none focus:border-[var(--barber-gold)]"
                style={{ backgroundColor: 'var(--barber-surface)' }}
                placeholder="ryan@dmtn.com.br"
              />
            </div>
            <div>
              <label className="block text-white/80 text-sm mb-2">Senha</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-4 py-3 border border-white/10 rounded-lg text-white placeholder-white/40 focus:outline-none focus:border-[var(--barber-gold)]"
                style={{ backgroundColor: 'var(--barber-surface)' }}
              />
            </div>
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full mt-6 py-3 text-black font-semibold rounded-lg transition disabled:opacity-50"
            style={{ backgroundColor: 'var(--barber-gold)' }}
          >
            {loading ? 'Entrando...' : 'Entrar'}
          </button>
        </form>
        <p className="text-sm text-center mt-6" style={{ color: 'var(--barber-text-muted)' }}>
          Demo: ryan@dmtn.com.br / admin123
        </p>
      </div>
    </div>
  );
}
