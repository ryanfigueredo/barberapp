/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async redirects() {
    return [
      { source: '/dashboard', destination: '/inicio', permanent: true },
      { source: '/dashboard/calendar', destination: '/agendamentos', permanent: true },
      { source: '/dashboard/appointments', destination: '/agendamentos', permanent: true },
      { source: '/dashboard/barbers', destination: '/barbeiros', permanent: true },
      { source: '/dashboard/services', destination: '/servicos', permanent: true },
      { source: '/dashboard/slots', destination: '/slots', permanent: true },
      { source: '/dashboard/whatsapp', destination: '/whatsapp', permanent: true },
      { source: '/dashboard/settings', destination: '/configuracoes', permanent: true },
    ];
  },
};

module.exports = nextConfig;
