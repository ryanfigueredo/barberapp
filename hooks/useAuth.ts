'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

export function useAuth() {
  const router = useRouter();
  const [apiKey, setApiKey] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const key = typeof window !== 'undefined' ? localStorage.getItem('api_key') : null;
    setApiKey(key);
    setReady(true);
  }, []);

  const headers = useMemo(
    () => ({
      'X-API-Key': apiKey || '',
      'Content-Type': 'application/json' as const,
    }),
    [apiKey]
  );

  const logout = useCallback(async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' });
    } catch {
      // ignore
    }
    localStorage.removeItem('api_key');
    localStorage.removeItem('user_role');
    localStorage.removeItem('user_barber_name');
    setApiKey(null);
    router.replace('/login');
  }, [router]);

  const fetchWithAuth = useCallback(
    async (url: string, options: RequestInit = {}) => {
      if (!apiKey) return new Response(null, { status: 401 });
      const res = await fetch(url, {
        ...options,
        headers: { ...headers, ...options.headers },
        credentials: 'include',
      });
      if (res.status === 401) {
        await logout();
      }
      return res;
    },
    [apiKey, headers, logout]
  );

  const hasApiKey = !!apiKey;

  return { apiKey, headers, logout, fetchWithAuth, hasApiKey, ready };
}
