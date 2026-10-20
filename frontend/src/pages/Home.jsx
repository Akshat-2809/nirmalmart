import { useQuery } from '@tanstack/react-query';
import { AnimatePresence, motion, useMotionValue, useScroll, useSpring, useTransform } from 'framer-motion';
import { ArrowRight, BadgeCheck, Clock, Headphones, RotateCcw, ShieldCheck, Sparkles, Star, Truck } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { catalogApi } from '../api';
import ProductGrid from '../components/product/ProductGrid';
import ProductRail from '../components/product/ProductRail';
import { Price } from '../components/ui/bits';
import { ease, fadeUp, Reveal, Stagger } from '../components/ui/motion';
import { useRecentlyViewed } from '../hooks/useRecentlyViewed';
import { cn } from '../lib/cn';
import { discountPct, productImage, sized } from '../lib/format';

const ROTATING = ['love', 'need', 'deserve', 'crave'];

function Hero({ picks }) {
  const ref = useRef(null);
  const [word, setWord] = useState(0);
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const sx = useSpring(mx, { stiffness: 60, damping: 18 });
  const sy = useSpring(my, { stiffness: 60, damping: 18 });
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start start', 'end start'] });
  const yBack = useTransform(scrollYProgress, [0, 1], [0, 120]);
  const yFront = useTransform(scrollYProgress, [0, 1], [0, -60]);

  useEffect(() => {
    const t = setInterval(() => setWord((w) => (w + 1) % ROTATING.length), 2200);
    return () => clearInterval(t);
  }, []);

  const onMove = (e) => {
    const r = ref.current.getBoundingClientRect();
    mx.set((e.clientX - r.left) / r.width - 0.5);
    my.set((e.clientY - r.top) / r.height - 0.5);
  };
  // Each collage card drifts a different amount with the cursor for depth
  const layers = [
    { x: useTransform(sx, (v) => v * -30), y: useTransform(sy, (v) => v * -30) },
    { x: useTransform(sx, (v) => v * 40), y: useTransform(sy, (v) => v * 30) },
    { x: useTransform(sx, (v) => v * -20), y: useTransform(sy, (v) => v * 45) },
  ];
  const headline = ['Shop', 'everything', 'you'];

  return (
    <section ref={ref} onMouseMove={onMove} className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-grid [mask-image:radial-gradient(ellipse_at_top,black_20%,transparent_70%)]" />
      <motion.div className="pointer-events-none absolute -left-40 -top-40 h-[520px] w-[520px] rounded-full bg-brand/20 blur-[120px]"
        animate={{ scale: [1, 1.15, 1], opacity: [0.6, 0.9, 0.6] }} transition={{ duration: 8, repeat: Infinity }} />
      <motion.div className="pointer-events-none absolute -right-32 top-20 h-[420px] w-[420px] rounded-full bg-deal/15 blur-[120px]"
        animate={{ scale: [1.1, 1, 1.1] }} transition={{ duration: 9, repeat: Infinity }} />

      <div className="container relative grid items-center gap-12 pb-16 pt-12 sm:pt-16 lg:grid-cols-[1.05fr_1fr] lg:pb-24 lg:pt-20">
        <div>
          <motion.span initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 rounded-full border border-line bg-surface px-3 py-1.5 text-xs font-semibold text-ink-soft shadow-soft">
            <span className="relative flex h-2 w-2"><span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-success opacity-75" /><span className="relative inline-flex h-2 w-2 rounded-full bg-success" /></span>
            New season, new arrivals — up to 50% off
          </motion.span>

          <h1 className="mt-6 font-display text-[44px] font-extrabold leading-[1.02] tracking-tight sm:text-6xl lg:text-7xl">
            {headline.map((w, i) => (
              <motion.span key={w} className="mr-[0.25em] inline-block"
                initial={{ opacity: 0, y: 40, rotate: 4 }} animate={{ opacity: 1, y: 0, rotate: 0 }}
                transition={{ duration: 0.8, ease, delay: 0.1 + i * 0.08 }}>
                {w}
              </motion.span>
            ))}
            <span className="relative inline-flex h-[1.1em] overflow-hidden align-bottom">
              <AnimatePresence mode="wait">
                <motion.span key={ROTATING[word]} className="inline-block bg-gradient-to-r from-brand via-fuchsia-500 to-deal bg-clip-text pb-2 text-transparent"
                  initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '-100%' }} transition={{ duration: 0.5, ease }}>
                  {ROTATING[word]}.
                </motion.span>
              </AnimatePresence>
            </span>
          </h1>

          <motion.p initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.45, ease }}
            className="mt-6 max-w-lg text-lg leading-relaxed text-ink-soft">
            Thousands of handpicked products across electronics, fashion, home and beauty — with fast delivery and easy returns.
          </motion.p>

          <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.55, ease }}
            className="mt-8 flex flex-wrap gap-3">
            <Link to="/shop" className="btn-primary btn-lg group">
              Start shopping <ArrowRight size={18} className="transition group-hover:translate-x-1" />
            </Link>
            <Link to="/shop?sort_by=discount" className="btn-outline btn-lg">Today’s deals</Link>
          </motion.div>

          <motion.dl initial="hidden" animate="show" variants={{ show: { transition: { staggerChildren: 0.1, delayChildren: 0.7 } } }}
            className="mt-12 grid max-w-md grid-cols-3 gap-6">
            {[['50K+', 'Happy customers'], ['4.8', 'Average rating'], ['24h', 'Express dispatch']].map(([n, l]) => (
              <motion.div key={l} variants={fadeUp}>
                <dt className="font-display text-2xl font-bold sm:text-3xl">{n}</dt>
                <dd className="mt-1 text-xs text-ink-faint">{l}</dd>
              </motion.div>
            ))}
          </motion.dl>
        </div>

        <div className="relative mx-auto aspect-square w-full max-w-[560px]">
          {picks.length >= 3 && (
            <>
              <motion.div style={{ y: yBack }} className="absolute inset-[8%] rounded-[40%_60%_55%_45%/55%_45%_55%_45%] bg-gradient-to-br from-brand/25 via-fuchsia-400/20 to-deal/25" />
              <motion.div style={layers[0]} className="absolute left-[6%] top-[6%] w-[52%]">
                <motion.div style={{ y: yFront }} initial={{ opacity: 0, scale: 0.8, rotate: -8 }} animate={{ opacity: 1, scale: 1, rotate: -4 }}
                  transition={{ duration: 0.9, ease, delay: 0.2 }} whileHover={{ rotate: 0, scale: 1.03 }}>
                  <HeroCard card={picks[0]} tall />
                </motion.div>
              </motion.div>
              <motion.div style={layers[1]} className="absolute right-[4%] top-[18%] w-[42%]">
                <motion.div initial={{ opacity: 0, scale: 0.8, rotate: 10 }} animate={{ opacity: 1, scale: 1, rotate: 5 }}
                  transition={{ duration: 0.9, ease, delay: 0.35 }} whileHover={{ rotate: 0, scale: 1.03 }}>
                  <HeroCard card={picks[1]} />
                </motion.div>
              </motion.div>
              <motion.div style={layers[2]} className="absolute bottom-[4%] left-[30%] w-[44%]">
                <motion.div initial={{ opacity: 0, scale: 0.8, rotate: -6 }} animate={{ opacity: 1, scale: 1, rotate: 3 }}
                  transition={{ duration: 0.9, ease, delay: 0.5 }} whileHover={{ rotate: 0, scale: 1.03 }}>
                  <HeroCard card={picks[2]} />
                </motion.div>
              </motion.div>
              <motion.div initial={{ opacity: 0, scale: 0 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.9, type: 'spring' }}
                className="absolute bottom-[6%] left-[4%] hidden h-24 w-24 place-items-center sm:grid">
                <motion.svg viewBox="0 0 100 100" className="absolute inset-0 h-full w-full text-ink" animate={{ rotate: 360 }} transition={{ duration: 14, repeat: Infinity, ease: 'linear' }}>
                  <defs><path id="circle" d="M50,50 m-37,0 a37,37 0 1,1 74,0 a37,37 0 1,1 -74,0" /></defs>
                  <text fontSize="11" fontWeight="700" letterSpacing="3" fill="currentColor"><textPath href="#circle">FREE DELIVERY • EASY RETURNS • </textPath></text>
                </motion.svg>
                <span className="grid h-11 w-11 place-items-center rounded-full bg-brand text-brand-ink shadow-glow"><Truck size={20} /></span>
              </motion.div>
            </>
          )}
        </div>
      </div>
    </section>
  );
}

/** Hero collage card: a product (with price) or, before any products exist, a category. */
const toHeroCard = (item) => (item.slug && item.price != null
  ? { to: `/product/${item.slug}`, image: productImage(item), title: item.name, tag: `₹${Math.round(item.price).toLocaleString('en-IN')}` }
  : { to: `/shop?category=${item.slug}`, image: item.image_url, title: item.name, tag: 'Shop' });

function HeroCard({ card, tall }) {
  return (
    <Link to={card.to} className="block overflow-hidden rounded-3xl border border-line bg-surface p-2 shadow-lift">
      <img src={sized(card.image, 600)} alt={card.title}
        className={cn('w-full rounded-2xl bg-muted object-cover', tall ? 'aspect-[4/5]' : 'aspect-square')} />
      <div className="flex items-center justify-between gap-2 px-2 py-2.5">
        <p className="truncate text-xs font-semibold">{card.title}</p>
        <span className="shrink-0 rounded-full bg-ink px-2 py-0.5 text-[11px] font-bold text-bg">{card.tag}</span>
      </div>
    </Link>
  );
}

function BrandMarquee() {
  const { data } = useQuery({ queryKey: ['facets', undefined, undefined], queryFn: () => catalogApi.facets({}), staleTime: 300_000 });
  const brands = data?.brands || [];
  if (brands.length < 4) return null; // a strip of one or two names looks empty
  return (
    <div className="border-y border-line bg-surface py-5">
      <div className="relative overflow-hidden [mask-image:linear-gradient(90deg,transparent,black_10%,black_90%,transparent)]">
        <div className="flex w-max animate-marquee gap-14 hover:[animation-play-state:paused]">
          {[...brands, ...brands].map((b, i) => (
            <span key={i} className="font-display text-xl font-bold text-ink-faint transition hover:text-ink">{b}</span>
          ))}
        </div>
      </div>
    </div>
  );
}

function Categories({ categories }) {
  if (!categories.length) return null;
  const spans = ['md:col-span-2 md:row-span-2', '', '', 'md:col-span-2', '', '', 'col-span-2'];
  return (
    <section className="container py-14 sm:py-20">
      <Reveal className="mb-8 flex items-end justify-between">
        <div>
          <p className="eyebrow mb-2">Browse</p>
          <h2 className="section-title">Shop by category</h2>
        </div>
        <Link to="/shop" className="group hidden items-center gap-1 text-sm font-semibold text-ink-soft hover:text-ink sm:flex">
          All products <ArrowRight size={16} className="transition group-hover:translate-x-1" />
        </Link>
      </Reveal>
      <Stagger className="grid auto-rows-[180px] grid-cols-2 gap-3 sm:gap-4 md:auto-rows-[200px] md:grid-cols-4">
        {categories.slice(0, 7).map((c, i) => (
          <motion.div key={c.id} variants={fadeUp} className={cn('col-span-1', spans[i])}>
            <Link to={`/shop?category=${c.slug}`} className="group relative block h-full overflow-hidden rounded-3xl bg-muted">
              {c.image_url && <img src={sized(c.image_url, 900)} alt="" loading="lazy" className="absolute inset-0 h-full w-full object-cover transition duration-[1.2s] ease-out group-hover:scale-110" />}
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />
              <div className="absolute inset-x-0 bottom-0 flex items-end justify-between p-4 sm:p-5">
                <div>
                  <h3 className={cn('font-display font-bold text-white', i === 0 ? 'text-2xl sm:text-3xl' : 'text-lg')}>{c.name}</h3>
                  <p className="text-xs text-white/75">{c.product_count} products</p>
                </div>
                <span className="grid h-9 w-9 -translate-x-2 place-items-center rounded-full bg-white text-ink opacity-0 transition duration-300 group-hover:translate-x-0 group-hover:opacity-100">
                  <ArrowRight size={16} />
                </span>
              </div>
            </Link>
          </motion.div>
        ))}
      </Stagger>
    </section>
  );
}

function useCountdown() {
  const end = () => { const d = new Date(); d.setHours(24, 0, 0, 0); return d; };
  const [left, setLeft] = useState(() => end() - new Date());
  useEffect(() => {
    const t = setInterval(() => setLeft(end() - new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  const s = Math.max(0, Math.floor(left / 1000));
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0'));
}

function DealOfTheDay({ product }) {
  const parts = useCountdown();
  if (!product) return null;
  const off = discountPct(product.price, product.compare_at_price);
  return (
    <section className="container py-10">
      <Reveal>
        <div className="relative overflow-hidden rounded-[2rem] bg-ink text-bg">
          <motion.div className="absolute -right-20 -top-20 h-80 w-80 rounded-full bg-brand/40 blur-[100px]"
            animate={{ x: [0, 40, 0], y: [0, 30, 0] }} transition={{ duration: 10, repeat: Infinity }} />
          <div className="relative grid items-center gap-8 p-6 sm:p-10 md:grid-cols-2 lg:p-14">
            <div>
              <span className="badge bg-deal text-white"><Clock size={12} /> Deal of the day</span>
              <h2 className="mt-4 font-display text-3xl font-extrabold leading-tight sm:text-4xl lg:text-5xl">{product.name}</h2>
              <div className="mt-5 flex items-baseline gap-3">
                <span className="font-display text-4xl font-bold">₹{Math.round(product.price).toLocaleString('en-IN')}</span>
                <span className="text-lg text-bg/50 line-through">₹{Math.round(product.compare_at_price).toLocaleString('en-IN')}</span>
                <span className="rounded-full bg-success px-2.5 py-1 text-sm font-bold text-white">{off}% off</span>
              </div>
              <div className="mt-6 flex gap-3" aria-label="Time left">
                {parts.map((n, i) => (
                  <div key={i} className="w-16 rounded-2xl bg-bg/10 py-3 text-center backdrop-blur">
                    <AnimatePresence mode="popLayout">
                      <motion.p key={n} initial={{ y: -14, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 14, opacity: 0 }}
                        className="font-display text-2xl font-bold tabular-nums">{n}</motion.p>
                    </AnimatePresence>
                    <p className="text-[10px] uppercase tracking-wider text-bg/60">{['hrs', 'min', 'sec'][i]}</p>
                  </div>
                ))}
              </div>
              <Link to={`/product/${product.slug}`} className="btn mt-8 bg-bg text-ink hover:bg-bg/90">
                Grab the deal <ArrowRight size={16} />
              </Link>
            </div>
            <motion.div whileHover={{ scale: 1.02, rotate: -1 }} className="relative mx-auto w-full max-w-sm">
              <img src={sized(productImage(product), 800)} alt={product.name} className="aspect-square w-full rounded-3xl object-cover shadow-2xl" />
              <motion.div animate={{ y: [0, -8, 0] }} transition={{ duration: 3, repeat: Infinity }}
                className="absolute -bottom-4 -left-4 flex items-center gap-2 rounded-2xl bg-surface px-4 py-3 text-ink shadow-lift">
                <Star size={18} className="text-amber-400" fill="currentColor" />
                <div><p className="text-sm font-bold">{Number(product.rating_avg).toFixed(1)} rating</p><p className="text-[11px] text-ink-faint">{product.sold_count}+ sold</p></div>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

function Trending({ categories }) {
  const [tab, setTab] = useState(null);
  const { data, isLoading } = useQuery({
    queryKey: ['products', { trending: tab }],
    queryFn: () => catalogApi.products({ category: tab || undefined, sort_by: 'popular', per_page: 8 }),
  });
  return (
    <section className="container py-14">
      <Reveal className="mb-8 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div><p className="eyebrow mb-2">Popular right now</p><h2 className="section-title">Trending this week</h2></div>
        <div className="no-scrollbar -mx-4 flex gap-1 overflow-x-auto px-4">
          {[{ slug: null, name: 'All' }, ...categories.slice(0, 5)].map((c) => (
            <button key={c.slug ?? 'all'} onClick={() => setTab(c.slug)}
              className={cn('relative shrink-0 rounded-full px-4 py-2 text-sm font-medium transition', tab === c.slug ? 'text-bg' : 'text-ink-soft hover:text-ink')}>
              {tab === c.slug && <motion.span layoutId="trend-tab" className="absolute inset-0 rounded-full bg-ink" transition={{ type: 'spring', stiffness: 400, damping: 32 }} />}
              <span className="relative">{c.name}</span>
            </button>
          ))}
        </div>
      </Reveal>
      <AnimatePresence mode="wait">
        <motion.div key={tab ?? 'all'} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
          <ProductGrid products={data?.items || []} loading={isLoading} />
        </motion.div>
      </AnimatePresence>
    </section>
  );
}

function ValueProps() {
  const items = [
    [Truck, 'Free delivery', 'On all orders above ₹499'],
    [RotateCcw, 'Easy returns', '7-day hassle-free returns'],
    [ShieldCheck, 'Secure payments', 'UPI, cards & net banking'],
    [Headphones, 'Here to help', 'Support 7 days a week'],
  ];
  return (
    <section className="container py-10">
      <Stagger className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        {items.map(([Icon, t, s]) => (
          <motion.div key={t} variants={fadeUp} whileHover={{ y: -4 }} className="card flex flex-col gap-3 p-5 transition hover:shadow-soft sm:flex-row sm:items-center">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand"><Icon size={22} /></span>
            <div><p className="font-semibold">{t}</p><p className="text-xs text-ink-faint">{s}</p></div>
          </motion.div>
        ))}
      </Stagger>
    </section>
  );
}

function Testimonials() {
  const quotes = [
    ['Aarav, Bengaluru', 'Delivery was a day early and the headphones sound incredible. My new go-to store.'],
    ['Diya, Chennai', 'Love how easy it is to find things. The packaging felt genuinely premium.'],
    ['Kabir, Delhi', 'Returned a pair of shoes with zero fuss. Refund landed in two days. 10/10.'],
  ];
  return (
    <section className="container py-14">
      <Reveal className="mb-8 text-center">
        <p className="eyebrow mb-2">Loved across India</p>
        <h2 className="section-title">What our customers say</h2>
      </Reveal>
      <Stagger className="grid gap-4 md:grid-cols-3">
        {quotes.map(([who, text]) => (
          <motion.figure key={who} variants={fadeUp} whileHover={{ y: -6 }} className="card p-6 transition hover:shadow-lift">
            <div className="flex gap-0.5 text-amber-400">{[...Array(5)].map((_, i) => <Star key={i} size={16} fill="currentColor" strokeWidth={0} />)}</div>
            <blockquote className="mt-4 text-[15px] leading-relaxed text-ink">“{text}”</blockquote>
            <figcaption className="mt-5 flex items-center gap-2 text-sm text-ink-soft"><BadgeCheck size={16} className="text-success" /> {who}</figcaption>
          </motion.figure>
        ))}
      </Stagger>
    </section>
  );
}

function CtaBand() {
  return (
    <section className="container py-10">
      <Reveal>
        <div className="relative overflow-hidden rounded-[2rem] bg-gradient-to-br from-brand via-violet-600 to-fuchsia-600 px-6 py-14 text-center text-white sm:px-12">
          <motion.div className="absolute inset-0 opacity-30" style={{ backgroundImage: 'radial-gradient(circle at 20% 20%, white 1px, transparent 1px)', backgroundSize: '28px 28px' }}
            animate={{ backgroundPosition: ['0px 0px', '28px 28px'] }} transition={{ duration: 4, repeat: Infinity, ease: 'linear' }} />
          <div className="relative">
            <Sparkles className="mx-auto" size={28} />
            <h2 className="mt-4 font-display text-3xl font-extrabold sm:text-5xl">Your first order? Get free delivery.</h2>
            <p className="mx-auto mt-4 max-w-xl text-white/80">Create an account in seconds to save your wishlist, track orders and check out faster.</p>
            <Link to="/register" className="btn btn-lg mt-8 bg-white text-ink hover:bg-white/90">Create free account</Link>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

export default function Home() {
  const { data: categories = [] } = useQuery({ queryKey: ['categories'], queryFn: catalogApi.categories, staleTime: 300_000 });
  const featured = useQuery({ queryKey: ['products', { featured: true }], queryFn: () => catalogApi.products({ featured: true, per_page: 24, sort_by: 'popular' }) });
  const deals = useQuery({ queryKey: ['products', { deals: true }], queryFn: () => catalogApi.products({ sort_by: 'discount', per_page: 10, in_stock: true }) });
  const topRated = useQuery({ queryKey: ['products', { rating: true }], queryFn: () => catalogApi.products({ sort_by: 'rating', per_page: 10 }) });
  const { items: recent } = useRecentlyViewed();

  const featuredItems = featured.data?.items || [];
  const hasProducts = (topRated.data?.total ?? 1) > 0;
  const heroPicks = [featuredItems.find((p) => p.category?.slug === 'fashion'), featuredItems.find((p) => p.category?.slug === 'electronics'), featuredItems.find((p) => p.category?.slug === 'home-living')]
    .filter(Boolean);
  const deal = deals.data?.items?.find((p) => p.price > 1500) || deals.data?.items?.[0];

  return (
    <>
      <Hero picks={(heroPicks.length === 3 ? heroPicks
        : featuredItems.length >= 3 ? featuredItems.slice(0, 3)
          : categories.filter((c) => c.image_url).slice(0, 3)).map(toHeroCard)} />
      <BrandMarquee />
      <Categories categories={categories} />
      <ProductRail eyebrow="Customer favourites" title="Bestsellers" products={featuredItems.slice(0, 12)} loading={featured.isLoading} href="/shop?sort_by=popular" />
      <DealOfTheDay product={deal} />
      <ProductRail eyebrow="Limited time" title="Biggest discounts" products={deals.data?.items} loading={deals.isLoading} href="/shop?sort_by=discount" />
      {hasProducts && <Trending categories={categories} />}
      <ValueProps />
      <ProductRail eyebrow="Rated 4★ and above" title="Top rated" products={topRated.data?.items} loading={topRated.isLoading} href="/shop?sort_by=rating" />
      <Testimonials />
      {recent.length > 0 && <ProductRail eyebrow="Pick up where you left off" title="Recently viewed" products={recent} />}
      <CtaBand />
    </>
  );
}
