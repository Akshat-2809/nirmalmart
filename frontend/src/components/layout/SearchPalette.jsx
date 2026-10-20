import { useQuery } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { ArrowRight, CornerDownLeft, Search, TrendingUp } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { catalogApi } from '../../api';
import { useUI } from '../../context/UIContext';
import { cn } from '../../lib/cn';
import { price, productImage, sized } from '../../lib/format';

const TRENDING = ['Headphones', 'Smartwatch', 'Sneakers', 'Sofa', 'Coffee', 'Yoga mat'];

function useDebounced(value, ms = 200) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return v;
}

export default function SearchPalette() {
  const { searchOpen: open, setSearchOpen } = useUI();
  const [q, setQ] = useState('');
  const [active, setActive] = useState(0);
  const input = useRef(null);
  const navigate = useNavigate();
  const term = useDebounced(q.trim());
  const { data: results = [], isFetching } = useQuery({
    queryKey: ['suggest', term], queryFn: () => catalogApi.suggest(term), enabled: term.length > 1, staleTime: 60_000,
  });

  const close = () => { setSearchOpen(false); setQ(''); setActive(0); };
  const goSearch = (text) => { navigate(`/shop?search=${encodeURIComponent(text)}`); close(); };
  const goProduct = (p) => { navigate(`/product/${p.slug}`); close(); };

  useEffect(() => { if (open) setTimeout(() => input.current?.focus(), 50); }, [open]);
  useEffect(() => setActive(0), [term]);

  const onKey = (e) => {
    if (e.key === 'Escape') close();
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((a) => Math.min(a + 1, results.length)); }
    if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)); }
    if (e.key === 'Enter' && q.trim()) {
      if (active > 0 && results[active - 1]) goProduct(results[active - 1]);
      else goSearch(q.trim());
    }
  };

  return createPortal(
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-[60] flex justify-center p-3 pt-[10vh]">
          <motion.div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={close}
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
          <motion.div role="dialog" aria-label="Search"
            initial={{ opacity: 0, y: -20, scale: 0.97 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: -10, scale: 0.98 }}
            transition={{ type: 'spring', stiffness: 380, damping: 30 }}
            className="relative h-fit w-full max-w-2xl overflow-hidden rounded-3xl border border-line bg-surface shadow-2xl">
            <div className="flex items-center gap-3 border-b border-line px-5">
              <Search size={20} className={cn('shrink-0 text-ink-faint', isFetching && 'animate-pulse text-brand')} />
              <input ref={input} value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={onKey}
                placeholder="Search for products, brands and more" aria-label="Search"
                className="h-16 flex-1 bg-transparent text-base outline-none placeholder:text-ink-faint" />
              <kbd className="rounded-md border border-line px-1.5 py-0.5 text-[10px] font-semibold text-ink-faint">ESC</kbd>
            </div>

            <div className="max-h-[60vh] overflow-y-auto p-2">
              {term.length < 2 ? (
                <div className="p-3">
                  <p className="mb-3 flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-ink-faint"><TrendingUp size={14} /> Trending</p>
                  <div className="flex flex-wrap gap-2">
                    {TRENDING.map((t, i) => (
                      <motion.button key={t} onClick={() => goSearch(t)} className="chip"
                        initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03 }}>
                        {t}
                      </motion.button>
                    ))}
                  </div>
                </div>
              ) : (
                <>
                  <button onClick={() => goSearch(q.trim())}
                    className={cn('flex w-full items-center gap-3 rounded-2xl px-3 py-3 text-left text-sm', active === 0 && 'bg-muted')}>
                    <Search size={16} className="text-ink-faint" />
                    <span className="flex-1">Search for “<b>{q.trim()}</b>”</span>
                    <CornerDownLeft size={14} className="text-ink-faint" />
                  </button>
                  {results.map((p, i) => (
                    <motion.button key={p.id} onClick={() => goProduct(p)} onMouseEnter={() => setActive(i + 1)}
                      initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.03 }}
                      className={cn('flex w-full items-center gap-3 rounded-2xl px-3 py-2 text-left', active === i + 1 && 'bg-muted')}>
                      <img src={sized(productImage(p), 120)} alt="" className="h-12 w-12 shrink-0 rounded-xl bg-muted object-cover" />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-medium">{p.name}</span>
                        <span className="block truncate text-xs text-ink-faint">{p.name_mr || p.category?.name}</span>
                      </span>
                      <span className="text-sm font-semibold">{price(p.price)}</span>
                      <ArrowRight size={14} className="text-ink-faint" />
                    </motion.button>
                  ))}
                  {!isFetching && results.length === 0 && (
                    <p className="px-3 py-6 text-center text-sm text-ink-faint">No quick matches — press Enter to search everything.</p>
                  )}
                </>
              )}
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
