import { motion } from 'framer-motion';
import { ArrowLeft } from 'lucide-react';
import { useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import { cn } from '../lib/cn';
import { store } from '../lib/storage';

const LANG_KEY = 'nm-info-lang';
const LANGS = [['en', 'English'], ['mr', 'मराठी']];

/** Help pages (Shipping, FAQs, Contact) read in English by default; the shopper's choice is remembered. */
export function useInfoLang() {
  const [lang, setLang] = useState(() => (store.get(LANG_KEY) === 'mr' ? 'mr' : 'en'));
  const change = (l) => { setLang(l); store.set(LANG_KEY, l); };
  return [lang, change];
}

function LangSwitch({ lang, onChange }) {
  return (
    <div role="group" aria-label="Language / भाषा" className="inline-flex shrink-0 rounded-full border border-line bg-surface p-1">
      {LANGS.map(([l, label]) => (
        <button key={l} type="button" lang={l} onClick={() => onChange(l)} aria-pressed={lang === l}
          className={cn('relative rounded-full px-3.5 py-1.5 text-sm font-semibold transition', lang === l ? 'text-brand-ink' : 'text-ink-soft hover:text-ink')}>
          {lang === l && <motion.span layoutId="info-lang" className="absolute inset-0 rounded-full bg-brand" transition={{ type: 'spring', stiffness: 400, damping: 32 }} />}
          <span className="relative">{label}</span>
        </button>
      ))}
    </div>
  );
}

const PAGES = [
  ['/shipping', { en: 'Shipping', mr: 'शिपिंग' }],
  ['/faq', { en: 'FAQs', mr: 'प्रश्नोत्तरे' }],
  ['/contact', { en: 'Contact us', mr: 'संपर्क' }],
];

/** Shared shell: heading, language switch and links between the help pages. */
export default function InfoPage({ lang, setLang, eyebrow, title, intro, children }) {
  return (
    <div className="container max-w-4xl py-10" lang={lang}>
      <Link to="/" className="group mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-brand hover:underline">
        <ArrowLeft size={16} className="transition group-hover:-translate-x-0.5" />
        {lang === 'mr' ? 'मुख्य पानावर परत जा' : 'Back to home'}
      </Link>
      <nav aria-label="Help pages" className="no-scrollbar -mx-4 mb-8 flex gap-1 overflow-x-auto px-4">
        {PAGES.map(([to, label]) => (
          <NavLink key={to} to={to}
            className={({ isActive }) => cn('shrink-0 rounded-full px-4 py-1.5 text-sm font-medium transition',
              isActive ? 'bg-muted text-ink' : 'text-ink-soft hover:text-ink')}>
            {label[lang]}
          </NavLink>
        ))}
      </nav>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0">
          <p className={cn('eyebrow', lang === 'mr' && 'normal-case tracking-normal')}>{eyebrow}</p>
          <h1 className="mt-2 font-display text-3xl font-extrabold sm:text-4xl">{title}</h1>
        </div>
        <LangSwitch lang={lang} onChange={setLang} />
      </div>
      <p className="mt-3 max-w-xl text-ink-soft">{intro}</p>
      {children}
    </div>
  );
}
