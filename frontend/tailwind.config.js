/** @type {import('tailwindcss').Config} */
const v = (name) => `rgb(var(--${name}) / <alpha-value>)`;

export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    container: { center: true, padding: { DEFAULT: '1rem', sm: '1.5rem', lg: '2rem' }, screens: { '2xl': '1320px' } },
    extend: {
      colors: {
        bg: v('bg'),
        surface: v('surface'),
        muted: v('muted'),
        ink: v('ink'),
        'ink-soft': v('ink-soft'),
        'ink-faint': v('ink-faint'),
        line: v('line'),
        brand: { DEFAULT: v('brand'), soft: v('brand-soft'), ink: v('brand-ink') },
        gold: v('gold'),
        maroon: v('maroon'),
        deal: v('deal'),
        success: v('success'),
        warning: v('warning'),
        danger: v('danger'),
      },
      fontFamily: {
        sans: ['Inter', '"Noto Sans Devanagari"', 'system-ui', 'sans-serif'],
        display: ['"Bricolage Grotesque"', 'Inter', '"Noto Sans Devanagari"', 'sans-serif'],
      },
      borderRadius: { xl: '0.875rem', '2xl': '1.25rem', '3xl': '1.75rem' },
      boxShadow: {
        soft: '0 1px 2px rgb(16 18 27 / 0.04), 0 4px 16px rgb(16 18 27 / 0.06)',
        lift: '0 2px 4px rgb(16 18 27 / 0.04), 0 18px 40px -12px rgb(16 18 27 / 0.18)',
        glow: '0 10px 30px -8px rgb(var(--brand) / 0.55)',
      },
      keyframes: {
        shimmer: { '100%': { transform: 'translateX(100%)' } },
        marquee: { from: { transform: 'translateX(0)' }, to: { transform: 'translateX(-50%)' } },
      },
      animation: {
        shimmer: 'shimmer 1.6s infinite',
        marquee: 'marquee 40s linear infinite',
      },
    },
  },
  plugins: [],
};
