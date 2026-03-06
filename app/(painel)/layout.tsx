'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';

const nav = [
  { href: '/inicio', label: 'Início' },
  { href: '/agendamentos', label: 'Agendamentos' },
  { href: '/barbeiros', label: 'Barbeiros', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/servicos', label: 'Serviços', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/slots', label: 'Slots', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/whatsapp', label: 'WhatsApp', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/configuracoes', label: 'Configurações', roles: ['owner', 'admin', 'super_admin'] },
];

export default function PainelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    const hasApiKey = typeof window !== 'undefined' && !!localStorage.getItem('api_key');
    if (!hasApiKey) {
      router.replace('/login');
    }
  }, [router]);

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: 'var(--barber-bg)' }}>
      <aside className="fixed left-0 top-0 bottom-0 w-64 flex flex-col shrink-0 z-10 border-r border-white/5"
        style={{ backgroundColor: 'var(--barber-surface-high)' }}>
          <div className="p-6 border-b border-white/5">
            <Link href="/inicio" className="font-display text-xl" style={{ color: 'var(--barber-gold)' }}>
              BarberApp
            </Link>
          </div>
          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            {nav
              .filter((item) => {
                const roles = (item as { roles?: string[] }).roles;
                if (!roles) return true;
                const role = typeof window !== 'undefined' ? localStorage.getItem('user_role') : null;
                return role && roles.includes(role);
              })
              .map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`block px-4 py-3 rounded-lg font-medium transition
                  ${pathname === item.href
                      ? 'text-[var(--barber-gold)]'
                      : 'text-white/70 hover:text-white hover:bg-white/5'
                  }`}
                style={pathname === item.href ? { backgroundColor: 'var(--barber-gold-bg)' } : undefined}
              >
                {item.label}
              </Link>
            ))}
          </nav>
          <div className="p-4 border-t border-white/5 shrink-0">
          <Link
            href="/login"
            className="block px-4 py-2 text-white/50 text-sm hover:text-white"
          >
              ← Sair
            </Link>
          </div>
        </aside>
      <main className="flex-1 min-w-0 ml-64 h-screen overflow-hidden flex flex-col">
        <div className="flex-1 flex flex-col min-h-0 overflow-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
