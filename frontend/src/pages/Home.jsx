import { useQuery } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { ArrowRight, ChevronLeft, ChevronRight, Clock, Flame, RotateCcw, ShieldCheck, Truck } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { catalogApi } from '../api';
import ProductGrid from '../components/product/ProductGrid';
import ProductRail from '../components/product/ProductRail';
import { ease, fadeUp, Reveal, Stagger } from '../components/ui/motion';
import { useRecentlyViewed } from '../hooks/useRecentlyViewed';
import { cn } from '../lib/cn';
import { discountPct, price, productImage, sized } from '../lib/format';

const maxOff = (items) => Math.max(0, ...items.map((p) => discountPct(p.price, p.compare_at_price)));
const byDiscount = (a, b) => discountPct(b.price, b.compare_at_price) - discountPct(a.price, a.compare_at_price);

/* ───────────── Deal banner carousel (built from real products) ───────────── */

const THEMES = {
  green: 'bg-gradient-to-br from-brand to-[#173d1d] text-white',
  maroon: 'bg-gradient-to-br from-maroon to-[#8f1d2a] text-white',
  gold: 'bg-gradient-to-br from-[#f5e6bf] to-gold text-[#2b2110]',
};

function useSlides(all, trending, categories) {
  return useMemo(() => {
    const slides = [];
    if (trending.length) {
      slides.push({
        key: 'trending', theme: 'green', badge: 'Trending now', title: 'Trending Gadgets', mr: 'ट्रेंडिंग गॅझेट्स',
        line: `Up to ${maxOff(trending)}% off`, href: '/shop?trending=true', images: [...trending].sort(byDiscount).slice(0, 3),
      });
    }
    const under999 = all.filter((p) => p.price < 1000);
    if (under999.length) {
      slides.push({
        key: 'u999', theme: 'maroon', badge: 'Budget picks', title: 'Under ₹999', mr: '₹999 पेक्षा कमी किमतीत',
        line: `${under999.length} gadgets at great prices`, href: '/shop?max_price=999', images: [...under999].sort(byDiscount).slice(0, 3),
      });
    }
    const top = [...categories].sort((a, b) => b.product_count - a.product_count).slice(0, 2);
    for (const c of top) {
      const items = all.filter((p) => p.category_id === c.id);
      if (!items.length) continue;
      slides.push({
        key: `c${c.id}`, theme: 'gold', badge: 'Shop by category', title: c.name, mr: c.name_mr,
        line: `From ${price(Math.min(...items.map((p) => p.price)))}`, href: `/shop?category=${c.slug}`, images: [...items].sort(byDiscount).slice(0, 3),
      });
    }
    return slides;
  }, [all, trending, categories]);
}

function PromoCarousel({ slides, loading }) {
  const [i, setI] = useState(0);
  const [paused, setPaused] = useState(false);
  const n = slides.length;
  const go = useCallback((d) => setI((x) => (x + d + n) % n), [n]);
  useEffect(() => {
    if (n < 2 || paused) return undefined;
    const t = setInterval(() => go(1), 5000);
    return () => clearInterval(t);
  }, [n, paused, go, i]);
  useEffect(() => { if (i >= n) setI(0); }, [n, i]);

  if (loading) return <div className="container pt-4"><div className="skeleton h-[180px] rounded-3xl sm:h-[240px] lg:h-[280px]" /></div>;
  if (!n) return null;
  const s = slides[Math.min(i, n - 1)];

  return (
    <section className="container pt-4" onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)} aria-roledescription="carousel">
      <div className="relative h-[180px] overflow-hidden rounded-3xl sm:h-[240px] lg:h-[280px]">
        <AnimatePresence initial={false} mode="popLayout">
          <motion.div key={s.key}
            initial={{ opacity: 0, x: 60 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -60 }} transition={{ duration: 0.5, ease }}
            drag={n > 1 ? 'x' : false} dragConstraints={{ left: 0, right: 0 }} dragElastic={0.2}
            onDragEnd={(_, info) => { if (info.offset.x < -50) go(1); if (info.offset.x > 50) go(-1); }}
            className={cn('absolute inset-0 flex items-center', THEMES[s.theme])}>
            <Link to={s.href} className="flex h-full w-full items-center gap-4 px-5 sm:px-14 lg:px-16" draggable={false}>
              <div className="min-w-0 flex-1">
                <span className="inline-flex items-center gap-1 rounded-full bg-white/20 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider backdrop-blur sm:text-[11px]">
                  <Flame size={12} /> {s.badge}
                </span>
                <h2 className="mt-2 font-display text-2xl font-extrabold leading-tight sm:mt-3 sm:text-4xl lg:text-5xl">{s.title}</h2>
                {s.mr && <p lang="mr" className="mt-0.5 text-sm font-semibold opacity-90 sm:text-lg">{s.mr}</p>}
                <p className="mt-1.5 text-sm font-medium opacity-90 sm:mt-2 sm:text-lg">{s.line}</p>
                <span className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-white px-4 py-2 text-xs font-bold text-ink shadow-sm sm:mt-5 sm:px-5 sm:text-sm">
                  Shop now <ArrowRight size={15} />
                </span>
              </div>
              <div className="flex shrink-0 items-center gap-3 lg:gap-4">
                {s.images.map((p, k) => (
                  <motion.div key={p.id} initial={{ y: 16, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.12 + k * 0.08, ease }}
                    className={cn('h-28 w-28 overflow-hidden rounded-2xl bg-white p-1.5 shadow-lift sm:h-36 sm:w-36 lg:h-44 lg:w-44',
                      k === 1 && 'hidden md:block', k === 2 && 'hidden lg:block')}>
                    <img src={sized(productImage(p), 400)} alt="" className="h-full w-full rounded-xl object-cover" draggable={false} />
                  </motion.div>
                ))}
              </div>
            </Link>
          </motion.div>
        </AnimatePresence>

        {n > 1 && (
          <>
            <button onClick={() => go(-1)} aria-label="Previous offer" className="absolute left-2 top-1/2 hidden h-10 w-10 -translate-y-1/2 place-items-center rounded-full bg-white/80 text-ink shadow backdrop-blur transition hover:bg-white sm:grid"><ChevronLeft size={20} /></button>
            <button onClick={() => go(1)} aria-label="Next offer" className="absolute right-2 top-1/2 hidden h-10 w-10 -translate-y-1/2 place-items-center rounded-full bg-white/80 text-ink shadow backdrop-blur transition hover:bg-white sm:grid"><ChevronRight size={20} /></button>
            <div className="absolute bottom-3 left-1/2 flex -translate-x-1/2 gap-1.5">
              {slides.map((x, k) => (
                <button key={x.key} onClick={() => setI(k)} aria-label={`Offer ${k + 1}`}
                  className={cn('h-1.5 rounded-full bg-white/90 transition-all', k === i ? 'w-6' : 'w-1.5 opacity-50')} />
              ))}
            </div>
          </>
        )}
      </div>
    </section>
  );
}

/* ───────────── Category circles (Amazon-app style) ───────────── */

function CategoryStrip({ categories, trendingImage }) {
  if (!categories.length) return null;
  const items = [
    ...(trendingImage ? [{ key: 'trending', to: '/shop?trending=true', name: 'Trending', mr: 'ट्रेंडिंग', image: trendingImage, hot: true }] : []),
    ...categories.map((c) => ({ key: c.id, to: `/shop?category=${c.slug}`, name: c.name, mr: c.name_mr, image: c.image_url })),
  ];
  return (
    <section className="container pt-6">
      <Stagger key={items.length} className="no-scrollbar -mx-4 flex gap-3 overflow-x-auto px-4 pb-1 sm:gap-6 lg:justify-center">
        {items.map((c) => (
          <motion.div key={c.key} variants={fadeUp} className="shrink-0">
            <Link to={c.to} className="group flex w-[76px] flex-col items-center text-center sm:w-24">
              <span className={cn('relative grid h-16 w-16 place-items-center overflow-hidden rounded-full border-2 bg-surface shadow-soft transition group-hover:-translate-y-1 group-hover:shadow-lift sm:h-20 sm:w-20',
                c.hot ? 'border-deal' : 'border-line group-hover:border-brand')}>
                {c.image ? <img src={sized(c.image, 200)} alt="" className="h-full w-full object-cover" /> : <Flame className="text-deal" />}
                {c.hot && <span className="absolute -bottom-0.5 rounded-full bg-deal px-1.5 text-[9px] font-bold uppercase text-white">Hot</span>}
              </span>
              <span className="mt-2 line-clamp-2 text-[12px] font-semibold leading-tight text-ink sm:text-[13px]">{c.name}</span>
              {c.mr && <span lang="mr" className="line-clamp-1 text-[11px] text-ink-faint">{c.mr}</span>}
            </Link>
          </motion.div>
        ))}
      </Stagger>
    </section>
  );
}

/* ───────────── Amazon-style quad deal cards ───────────── */

function QuadCard({ title, mr, items, href, cta = 'See all' }) {
  const shown = items.slice(0, 4);
  return (
    <motion.div variants={fadeUp} className="card flex w-[78%] shrink-0 snap-start flex-col p-4 transition hover:shadow-lift sm:w-[46%] lg:w-auto">
      <h3 className="font-display text-lg font-bold leading-tight">{title}</h3>
      {mr && <p lang="mr" className="text-sm text-ink-soft">{mr}</p>}
      <div className={cn('mt-3 grid flex-1 content-start gap-3', shown.length > 1 ? 'grid-cols-2' : 'grid-cols-1')}>
        {shown.map((p) => {
          const off = discountPct(p.price, p.compare_at_price);
          return (
            <Link key={p.id} to={`/product/${p.slug}`} className="group">
              <div className={cn('overflow-hidden rounded-xl bg-muted', shown.length > 1 ? 'aspect-square' : 'aspect-[4/3]')}>
                <img src={sized(productImage(p), 300)} alt={p.name} loading="lazy" className="h-full w-full object-cover transition duration-500 group-hover:scale-105" />
              </div>
              <p className="mt-1.5 line-clamp-1 text-xs text-ink-soft">{p.name}</p>
              <p className="flex items-center gap-1.5 text-xs">
                <b className="text-ink">{price(p.price)}</b>
                {off > 0 && <span className="rounded bg-deal px-1 text-[10px] font-bold text-white">-{off}%</span>}
              </p>
            </Link>
          );
        })}
      </div>
      <Link to={href} className="mt-3 text-sm font-semibold text-brand hover:underline">{cta}</Link>
    </motion.div>
  );
}

function DealCards({ all, trending, categories }) {
  const cards = [];
  if (trending.length) cards.push({ key: 't', title: `Up to ${maxOff(trending)}% off | Trending`, mr: 'ट्रेंडिंग गॅझेट्सवर सवलत', items: [...trending].sort(byDiscount), href: '/shop?trending=true', cta: 'See all deals' });
  for (const c of [...categories].sort((a, b) => b.product_count - a.product_count)) {
    if (cards.length >= 4) break;
    const items = all.filter((p) => p.category_id === c.id);
    if (items.length) cards.push({ key: c.id, title: c.name, mr: c.name_mr, items: [...items].sort(byDiscount), href: `/shop?category=${c.slug}`, cta: `Explore ${c.name}` });
  }
  if (!cards.length) return null;
  return (
    <section className="container pt-8">
      <Stagger key={cards.length} className="no-scrollbar -mx-4 flex snap-x snap-mandatory scroll-px-4 gap-4 overflow-x-auto px-4 pb-1 lg:mx-0 lg:grid lg:grid-cols-4 lg:overflow-visible lg:px-0">
        {cards.map(({ key, ...c }) => <QuadCard key={key} {...c} />)}
      </Stagger>
    </section>
  );
}

/* ───────────── Today's deals with countdown ───────────── */

function useCountdown() {
  const end = () => { const d = new Date(); d.setHours(24, 0, 0, 0); return d; };
  const [left, setLeft] = useState(() => end() - new Date());
  useEffect(() => {
    const t = setInterval(() => setLeft(end() - new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  const s = Math.max(0, Math.floor(left / 1000));
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((x) => String(x).padStart(2, '0')).join(':');
}

function TodaysDeals({ items, loading }) {
  const ends = useCountdown();
  const deals = items.filter((p) => discountPct(p.price, p.compare_at_price) >= 10);
  if (!loading && !deals.length) return null;
  return (
    <section className="container pt-10">
      <div className="mb-4 flex flex-wrap items-center gap-x-4 gap-y-2">
        <h2 className="font-display text-xl font-bold sm:text-2xl">Today’s Deals</h2>
        <span className="inline-flex items-center gap-1.5 rounded-full bg-deal/10 px-3 py-1 text-xs font-bold text-deal">
          <Clock size={13} /> Ends in <span className="tabular-nums">{ends}</span>
        </span>
        <Link to="/shop?sort_by=discount" className="group ml-auto flex items-center gap-1 text-sm font-semibold text-brand">
          See all <ArrowRight size={15} className="transition group-hover:translate-x-1" />
        </Link>
      </div>
      <ProductGrid products={deals.slice(0, 12)} loading={loading} skeletons={5}
        cols="no-scrollbar -mx-4 grid auto-cols-[44%] grid-flow-col gap-4 overflow-x-auto px-4 pb-2 snap-x scroll-px-4 sm:auto-cols-[30%] lg:auto-cols-[calc((100%-4rem)/5)] [&>*]:snap-start" />
    </section>
  );
}

/* ───────────── Trending grid ───────────── */

function Trending({ items, loading }) {
  if (!loading && !items.length) return null;
  return (
    <section className="container pt-12">
      <Reveal className="mb-4 flex items-end justify-between gap-4">
        <div>
          <h2 className="font-display text-xl font-bold sm:text-2xl">🔥 Trending Gadgets</h2>
          <p lang="mr" className="text-sm font-semibold text-ink-soft">ट्रेंडिंग गॅझेट्स</p>
        </div>
        <Link to="/shop?trending=true" className="group flex shrink-0 items-center gap-1 text-sm font-semibold text-brand">
          View all <ArrowRight size={15} className="transition group-hover:translate-x-1" />
        </Link>
      </Reveal>
      <ProductGrid products={items.slice(0, 10)} loading={loading} skeletons={5}
        cols="grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-3 lg:grid-cols-5" />
    </section>
  );
}

/* ───────────── Shop by price ───────────── */

const BUCKETS = [
  { label: 'Under ₹499', mr: '₹499 पेक्षा कमी', max: 499, cls: 'from-brand-soft to-surface' },
  { label: 'Under ₹999', mr: '₹999 पेक्षा कमी', max: 999, cls: 'from-[#f5e6bf] to-surface dark:from-[#3a2f17]' },
  { label: 'Under ₹1,499', mr: '₹1,499 पेक्षा कमी', max: 1499, cls: 'from-[#f6dfe2] to-surface dark:from-[#3a1a1e]' },
  { label: '₹1,500 & above', mr: '₹1,500 आणि अधिक', min: 1500, cls: 'from-muted to-surface' },
];

function PriceBuckets({ all }) {
  const buckets = BUCKETS.map((b) => ({ ...b, count: all.filter((p) => (b.max ? p.price <= b.max : p.price >= b.min)).length }))
    .filter((b) => b.count > 0);
  if (buckets.length < 2) return null;
  return (
    <section className="container pt-12">
      <h2 className="mb-4 font-display text-xl font-bold sm:text-2xl">Shop by price</h2>
      <Stagger className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        {buckets.map((b) => (
          <motion.div key={b.label} variants={fadeUp}>
            <Link to={b.max ? `/shop?max_price=${b.max}` : `/shop?min_price=${b.min}`}
              className={cn('group block rounded-2xl border border-line bg-gradient-to-br p-4 transition hover:-translate-y-1 hover:shadow-lift sm:p-5', b.cls)}>
              <p className="font-display text-lg font-extrabold sm:text-2xl">{b.label}</p>
              <p lang="mr" className="text-xs text-ink-soft sm:text-sm">{b.mr}</p>
              <p className="mt-3 flex items-center gap-1 text-xs font-semibold text-brand">{b.count} products <ArrowRight size={13} className="transition group-hover:translate-x-1" /></p>
            </Link>
          </motion.div>
        ))}
      </Stagger>
    </section>
  );
}

/* ───────────── Explore all: categories interleaved, reshuffled daily ───────────── */

const seeded = (seed) => () => { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; };

function mixProducts(all) {
  const rand = seeded(Number(new Date().toISOString().slice(0, 10).replace(/-/g, '')));   // same order all day
  const groups = new Map();
  for (const p of all) {
    const k = p.category_id ?? 0;
    if (!groups.has(k)) groups.set(k, []);
    groups.get(k).push(p);
  }
  const lists = [...groups.values()].map((g) => g.map((p) => [rand(), p]).sort((a, b) => a[0] - b[0]).map((x) => x[1]))
    .sort(() => rand() - 0.5);
  const out = [];
  for (let i = 0; out.length < all.length; i++) for (const g of lists) if (g[i]) out.push(g[i]);   // round-robin across categories
  return out;
}

function ExploreAll({ all, loading }) {
  const mixed = useMemo(() => mixProducts(all), [all]);
  const [shown, setShown] = useState(20);
  if (!loading && !all.length) return null;
  return (
    <section className="container pt-12">
      <div className="mb-4 flex items-end justify-between gap-4">
        <div>
          <h2 className="font-display text-xl font-bold sm:text-2xl">Explore all products</h2>
          <p lang="mr" className="text-sm font-semibold text-ink-soft">सर्व उत्पादने</p>
        </div>
        <Link to="/shop" className="group flex shrink-0 items-center gap-1 text-sm font-semibold text-brand">
          Shop all <ArrowRight size={15} className="transition group-hover:translate-x-1" />
        </Link>
      </div>
      <ProductGrid products={mixed.slice(0, shown)} loading={loading} skeletons={10}
        cols="grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-3 lg:grid-cols-5" />
      {shown < mixed.length && (
        <div className="mt-8 text-center">
          <button onClick={() => setShown((n) => n + 20)} className="btn-outline">Show more ({mixed.length - shown} left)</button>
        </div>
      )}
    </section>
  );
}

/* ───────────── Slim trust strip ───────────── */

function TrustStrip() {
  const items = [[Truck, 'Free delivery above ₹499'], [RotateCcw, '7-day easy returns'], [ShieldCheck, 'Secure payments']];
  return (
    <section className="container pt-12">
      <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 rounded-2xl border border-line bg-surface px-4 py-4 text-sm text-ink-soft">
        {items.map(([Icon, t]) => <span key={t} className="flex items-center gap-2"><Icon size={17} className="text-brand" /> {t}</span>)}
      </div>
    </section>
  );
}

export default function Home() {
  const { data: categories = [], isLoading: catsLoading } = useQuery({ queryKey: ['categories'], queryFn: catalogApi.categories, staleTime: 300_000 });
  const allQ = useQuery({ queryKey: ['products', { home: 'all' }], queryFn: () => catalogApi.products({ sort_by: 'newest', per_page: 100 }) });
  const trendQ = useQuery({ queryKey: ['products', { trending: true }], queryFn: () => catalogApi.products({ trending: true, sort_by: 'newest', per_page: 24 }) });
  const { items: recent } = useRecentlyViewed();

  const all = allQ.data?.items || [];
  const trending = trendQ.data?.items || [];
  const slides = useSlides(all, trending, categories);
  const loading = allQ.isLoading || trendQ.isLoading;
  const deals = [...all].filter((p) => p.stock_quantity > 0).sort(byDiscount);

  return (
    <div className="pb-6">
      <PromoCarousel slides={slides} loading={loading || catsLoading} />
      <CategoryStrip categories={categories} trendingImage={trending[0] ? productImage(trending[0]) : null} />
      <DealCards all={all} trending={trending} categories={categories} />
      <TodaysDeals items={deals} loading={allQ.isLoading} />
      <Trending items={trending} loading={trendQ.isLoading} />
      <PriceBuckets all={all} />
      <ExploreAll all={all} loading={allQ.isLoading} />
      {recent.length > 0 && <ProductRail eyebrow="Pick up where you left off" title="Recently viewed" products={recent} />}
      <TrustStrip />
    </div>
  );
}
