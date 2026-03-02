'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';

const nav = [
  { href: '/dashboard', label: 'Início' },
  { href: '/dashboard/calendar', label: 'Calendário' },
  { href: '/dashboard/appointments', label: 'Agendamentos' },
  { href: '/dashboard/barbers', label: 'Barbeiros', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/dashboard/services', label: 'Serviços', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/dashboard/slots', label: 'Slots', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/dashboard/whatsapp', label: 'WhatsApp', roles: ['owner', 'admin', 'super_admin'] },
  { href: '/dashboard/settings', label: 'Configurações', roles: ['owner', 'admin', 'super_admin'] },
];

export default function DashboardLayout({
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
    <div className="min-h-screen bg-[#0A0A0A] flex">
      <aside className="w-64 bg-[#1A1A1A] border-r border-white/5 flex flex-col shrink-0">
          <div className="p-6 border-b border-white/5">
            <Link href="/dashboard" className="font-display text-xl text-[#F5C518]">
              BarberApp
            </Link>
          </div>
          <nav className="flex-1 p-4 space-y-1">
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
                  ${
                    pathname === item.href
                      ? 'bg-[#F5C518]/20 text-[#F5C518]'
                      : 'text-white/70 hover:text-white hover:bg-white/5'
                  }`}
              >
                {item.label}
              </Link>
            ))}
          </nav>
          <div className="p-4 border-t border-white/5">
          <Link
            href="/login"
            className="block px-4 py-2 text-white/50 text-sm hover:text-white"
          >
              ← Sair
            </Link>
          </div>
        </aside>
      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  );
}
