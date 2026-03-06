import Link from 'next/link';

export const metadata = {
  title: 'Política de Privacidade — BarberApp',
  description: 'Política de privacidade do BarberApp, sistema de agendamento para barbearias.',
};

export default function PoliticaDePrivacidadePage() {
  return (
    <main className="min-h-screen bg-[#141416] text-white">
      <div className="max-w-3xl mx-auto px-6 py-12">
        <Link
          href="/"
          className="inline-flex items-center text-[#D9AE59] hover:opacity-90 transition mb-8"
        >
          ← Voltar
        </Link>
        <h1 className="text-3xl font-bold font-['Playfair_Display'] text-[#D9AE59] mb-2">
          Política de Privacidade
        </h1>
        <p className="text-white/70 text-sm mb-10">BarberApp — Sistema de Agendamento</p>

        <div className="prose prose-invert prose-sm max-w-none space-y-8 text-white/90">
          <section>
            <h2 className="text-xl font-semibold text-white mb-3">1. Introdução</h2>
            <p>
              Esta Política de Privacidade descreve como o BarberApp (“nós”, “nosso” ou “aplicativo”) coleta, usa e protege as informações dos usuários do sistema de agendamento para estabelecimentos de barbearia, incluindo o uso integrado ao WhatsApp.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">2. Dados que coletamos</h2>
            <p className="mb-2">Podemos coletar:</p>
            <ul className="list-disc pl-6 space-y-1 text-white/80">
              <li>Nome e número de telefone (para agendamentos e comunicação via WhatsApp)</li>
              <li>Dados de agendamentos (data, horário, serviço, barbearia)</li>
              <li>Informações de uso do sistema (para melhorar o serviço)</li>
              <li>Dados necessários ao funcionamento do negócio (barbearias/clientes que utilizam o app)</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">3. Uso dos dados</h2>
            <p>
              Utilizamos os dados para gerenciar agendamentos, enviar lembretes e comunicações via WhatsApp, operar o dashboard das barbearias e cumprir obrigações legais quando aplicável.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">4. WhatsApp</h2>
            <p>
              O envio e o recebimento de mensagens pelo WhatsApp estão sujeitos à Política de Privacidade do WhatsApp (Meta). Não armazenamos o conteúdo das conversas além do necessário para o agendamento e o atendimento ao cliente.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">5. Compartilhamento</h2>
            <p>
              Não vendemos dados pessoais. Podemos compartilhar dados apenas com prestadores de serviço essenciais (hospedagem, APIs) e quando exigido por lei.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">6. Segurança e retenção</h2>
            <p>
              Adotamos medidas técnicas para proteger os dados. Mantemos as informações pelo tempo necessário à prestação do serviço e às obrigações legais.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">7. Seus direitos</h2>
            <p>
              Você pode solicitar acesso, correção ou exclusão dos seus dados entrando em contato conosco pelo canal indicado no aplicativo ou no site.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">8. Alterações</h2>
            <p>
              Esta política pode ser atualizada. A versão vigente estará publicada em barber.dmtn.com.br/politica-de-privacidade, com data da última atualização.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-white mb-3">9. Contato</h2>
            <p>
              Dúvidas sobre esta política: entre em contato através dos canais disponíveis no site ou no aplicativo BarberApp.
            </p>
          </section>
        </div>

        <p className="mt-12 text-white/50 text-sm">
          Última atualização: março de 2025.
        </p>
        <Link
          href="/"
          className="inline-block mt-6 px-6 py-3 bg-[#D9AE59] text-black font-semibold rounded-lg hover:opacity-90 transition"
        >
          Voltar ao início
        </Link>
      </div>
    </main>
  );
}
