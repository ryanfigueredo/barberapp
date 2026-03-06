export default function HomePage() {
  return (
    <main className="min-h-screen bg-[#141416] flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-[#D9AE59] font-['Playfair_Display']">
          BarberApp
        </h1>
        <p className="text-white/80 mt-2">Sistema de Agendamento para Barbearias</p>
        <a
          href="/login"
          className="inline-block mt-6 px-6 py-3 bg-[#D9AE59] text-black font-semibold rounded-lg hover:opacity-90 transition"
        >
          Acessar Dashboard
        </a>
      </div>
    </main>
  );
}
