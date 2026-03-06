import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        display: ['var(--font-playfair)', 'serif'],
        body: ['var(--font-dm-sans)', 'sans-serif'],
        sans: ['var(--font-dm-sans)', 'sans-serif'],
      },
      colors: {
        barber: {
          black: '#141416',
          card: '#1C1C1E',
          gold: '#D9AE59',
          goldDim: 'rgba(217, 174, 89, 0.25)',
          surface: 'rgba(255, 255, 255, 0.06)',
          success: '#36D66B',
          warning: '#F59E0B',
          danger: '#F04545',
          blue: '#3B82F6',
        },
      },
    },
  },
  plugins: [],
};

export default config;
