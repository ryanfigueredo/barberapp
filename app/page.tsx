import Link from 'next/link';
import {
  MessageCircle,
  Smartphone,
  LayoutDashboard,
  Calendar,
  CheckCircle2,
  ArrowRight,
} from 'lucide-react';
import FadeInSection from '@/components/FadeInSection';

export default function HomePage() {
  return (
    <main
      className="min-h-screen overflow-x-hidden"
      style={{ backgroundColor: 'var(--barber-bg)' }}
    >
      {/* Navbar */}
      <nav
        className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 md:px-10 md:py-5 opacity-0 animate-fade-in-up"
        style={{ animationDelay: '100ms', animationFillMode: 'forwards' }}
      >
        <div
          className="rounded-xl px-4 py-2 transition-transform hover:scale-[1.02]"
          style={{ background: 'var(--barber-surface)' }}
        >
          <span
            className="font-display text-xl font-bold tracking-tight"
            style={{ color: 'var(--barber-gold)' }}
          >
            BarberApp
          </span>
        </div>
        <Link
          href="/login"
          className="btn-gold flex items-center gap-2 rounded-xl px-5 py-2.5 font-semibold transition-all duration-300 hover:scale-[1.03]"
          style={{
            backgroundColor: 'var(--barber-gold)',
            color: '#141416',
          }}
        >
          Acessar
          <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" strokeWidth={2.5} />
        </Link>
      </nav>

      {/* Hero */}
      <section className="relative pt-32 pb-20 px-6 md:pt-40 md:pb-28 md:px-12">
        <div className="mx-auto max-w-4xl text-center">
          <p
            className="mb-4 text-sm font-semibold tracking-widest uppercase opacity-0 animate-fade-in-up"
            style={{ color: 'var(--barber-gold)', animationDelay: '200ms', animationFillMode: 'forwards' }}
          >
            Sistema de agendamento para barbearias
          </p>
          <h1
            className="font-display text-4xl font-bold leading-[1.1] tracking-tight md:text-6xl lg:text-7xl opacity-0 animate-fade-in-up"
            style={{ color: 'var(--barber-text)', animationDelay: '300ms', animationFillMode: 'forwards' }}
          >
            Seu cliente agenda
            <br />
            <span style={{ color: 'var(--barber-gold)' }}>direto pelo WhatsApp</span>
          </h1>
          <p
            className="mx-auto mt-6 max-w-xl text-lg md:text-xl opacity-0 animate-fade-in-up"
            style={{ color: 'var(--barber-text-secondary)', animationDelay: '450ms', animationFillMode: 'forwards' }}
          >
            Dashboard completo, app para clientes e integração nativa com WhatsApp.
            Zero papéis, zero atrasos.
          </p>
          <div
            className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center opacity-0 animate-fade-in-up"
            style={{ animationDelay: '600ms', animationFillMode: 'forwards' }}
          >
            <Link
              href="/login"
              className="btn-gold group flex items-center gap-2 rounded-xl px-8 py-4 font-semibold transition-all duration-300 hover:scale-[1.03]"
              style={{
                backgroundColor: 'var(--barber-gold)',
                color: '#141416',
              }}
            >
              Começar agora
              <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" strokeWidth={2.5} />
            </Link>
            <a
              href="#como-funciona"
              className="flex items-center gap-2 rounded-xl px-6 py-3 font-medium transition-all duration-300 hover:border-[var(--barber-gold)] hover:opacity-100"
              style={{
                border: '1px solid var(--barber-border)',
                color: 'var(--barber-text-secondary)',
              }}
            >
              Como funciona
            </a>
          </div>
        </div>
      </section>

      {/* Features — Bento-style grid (ui-ux-pro-max: pattern 28) */}
      <section
        id="como-funciona"
        className="px-6 py-16 md:px-12 md:py-24"
      >
        <div className="mx-auto max-w-6xl">
          <FadeInSection>
            <h2
              className="font-display text-center text-3xl font-bold md:text-4xl"
              style={{ color: 'var(--barber-text)' }}
            >
              Tudo que sua barbearia precisa
            </h2>
            <p
              className="mx-auto mt-4 max-w-2xl text-center"
              style={{ color: 'var(--barber-text-secondary)' }}
            >
              Gestão de agendamentos, barbeiros e serviços em um único lugar.
            </p>
          </FadeInSection>
          <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {[
              {
                icon: MessageCircle,
                title: 'Agendamento por WhatsApp',
                desc: 'Cliente agenda pelo celular, sem ligar. Confirmação automática.',
              },
              {
                icon: Smartphone,
                title: 'App para clientes',
                desc: 'Escolhe barbeiro, serviço e horário. Tudo na palma da mão.',
              },
              {
                icon: LayoutDashboard,
                title: 'Dashboard de gestão',
                desc: 'Agendamentos, barbeiros, serviços e slots em tempo real.',
              },
              {
                icon: Calendar,
                title: 'Slots configuráveis',
                desc: 'Defina horários, intervalos e disponibilidade por barbeiro.',
              },
            ].map((f, i) => (
              <FadeInSection key={f.title} delay={i * 100}>
                <div
                  className="group rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1 hover:scale-[1.02]"
                  style={{
                    backgroundColor: 'var(--barber-surface)',
                    border: '1px solid var(--barber-border)',
                    boxShadow: '0 0 0 rgba(217,174,89,0)',
                  }}
                >
                  <div
                    className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl transition-transform duration-300 group-hover:scale-110"
                    style={{ backgroundColor: 'var(--barber-gold-bg)' }}
                  >
                    <f.icon
                      className="h-6 w-6"
                      style={{ color: 'var(--barber-gold)' }}
                      strokeWidth={1.8}
                    />
                  </div>
                  <h3
                    className="font-display text-lg font-semibold"
                    style={{ color: 'var(--barber-text)' }}
                  >
                    {f.title}
                  </h3>
                  <p
                    className="mt-2 text-sm"
                    style={{ color: 'var(--barber-text-secondary)' }}
                  >
                    {f.desc}
                  </p>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>

      {/* Benefits strip */}
      <FadeInSection>
        <section
          className="border-y px-6 py-12 md:px-12"
          style={{ borderColor: 'var(--barber-border)' }}
        >
          <div className="mx-auto flex max-w-4xl flex-wrap items-center justify-center gap-8 md:gap-16">
            {[
              'Sem fila de espera',
              'Menos no-shows',
              'Gestão profissional',
            ].map((b) => (
              <div
                key={b}
                className="flex items-center gap-3 transition-transform duration-200 hover:scale-105"
              >
                <CheckCircle2
                  className="h-5 w-5 shrink-0"
                  style={{ color: 'var(--barber-gold)' }}
                  strokeWidth={2}
                />
                <span
                  className="font-medium"
                  style={{ color: 'var(--barber-text)' }}
                >
                  {b}
                </span>
              </div>
            ))}
          </div>
        </section>
      </FadeInSection>

      {/* CTA final */}
      <section className="px-6 py-20 md:px-12 md:py-28">
        <FadeInSection>
          <div
            className="mx-auto max-w-3xl rounded-2xl px-8 py-14 text-center md:px-12 md:py-16 transition-transform duration-300 hover:scale-[1.01]"
            style={{
              backgroundColor: 'var(--barber-surface)',
              border: '1px solid var(--barber-border)',
            }}
          >
            <h2
              className="font-display text-3xl font-bold md:text-4xl"
              style={{ color: 'var(--barber-text)' }}
            >
              Pronto para simplificar sua barbearia?
            </h2>
            <p
              className="mt-4"
              style={{ color: 'var(--barber-text-secondary)' }}
            >
              Acesse o dashboard e comece a receber agendamentos pelo WhatsApp.
            </p>
            <Link
              href="/login"
              className="btn-gold mt-8 inline-flex items-center gap-2 rounded-xl px-8 py-4 font-semibold transition-all duration-300 hover:scale-105"
              style={{
                backgroundColor: 'var(--barber-gold)',
                color: '#141416',
              }}
            >
              Acessar BarberApp
              <ArrowRight className="h-5 w-5" strokeWidth={2.5} />
            </Link>
          </div>
        </FadeInSection>
      </section>

      {/* Footer */}
      <footer
        className="border-t px-6 py-8 md:px-12"
        style={{ borderColor: 'var(--barber-border)' }}
      >
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 md:flex-row">
          <span
            className="font-display text-lg font-bold"
            style={{ color: 'var(--barber-gold)' }}
          >
            BarberApp
          </span>
          <div
            className="flex gap-6 text-sm"
            style={{ color: 'var(--barber-text-muted)' }}
          >
            <Link href="/login" className="transition hover:opacity-80">
              Login
            </Link>
            <Link href="/politica-de-privacidade" className="transition hover:opacity-80">
              Política de privacidade
            </Link>
          </div>
        </div>
        <p
          className="mt-6 text-center text-xs"
          style={{ color: 'var(--barber-text-muted)' }}
        >
          © {new Date().getFullYear()} DMTN Sistemas. Sistema de agendamento para barbearias.
        </p>
      </footer>
    </main>
  );
}
