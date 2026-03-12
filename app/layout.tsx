import type { Metadata } from 'next';
import { Playfair_Display, DM_Sans } from 'next/font/google';
import { Toaster } from 'react-hot-toast';
import './globals.css';

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-playfair',
});
const dmSans = DM_Sans({
  subsets: ['latin'],
  variable: '--font-dm-sans',
});

export const metadata: Metadata = {
  title: 'BarberApp — Sistema de Agendamento',
  description: 'Sistema de agendamento para barbearias via WhatsApp',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR" className={`${playfair.variable} ${dmSans.variable}`}>
      <body className="font-sans antialiased text-white" style={{ backgroundColor: 'var(--barber-bg)' }}>
        {children}
        <Toaster
          position="top-center"
          toastOptions={{
            style: {
              background: 'var(--barber-surface-high)',
              border: '1px solid var(--barber-border)',
              color: 'white',
            },
          }}
        />
      </body>
    </html>
  );
}
