export default function HomePage() {
  return (
    <main className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-[#F5C518] font-['Playfair_Display']">
          BarberApp
        </h1>
        <p className="text-white/80 mt-2">Sistema de Agendamento para Barbearias</p>
        <a
          href="/login"
          className="inline-block mt-6 px-6 py-3 bg-[#F5C518] text-black font-semibold rounded-lg hover:bg-amber-500 transition"
        >
          Acessar Dashboard
        </a>
      </div>
    </main>
  );
}
