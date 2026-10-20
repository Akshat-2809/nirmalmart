import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { BadgeCheck, Check, ChevronRight, MapPin, PackageCheck, RotateCcw, Share2, ShieldCheck, ShoppingBag, Truck, Zap } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { catalogApi } from '../api';
import { errorMessage } from '../api/client';
import ProductRail from '../components/product/ProductRail';
import { HeartButton } from '../components/product/ProductCard';
import { Price, Qty, Skeleton, Stars } from '../components/ui/bits';
import { ease } from '../components/ui/motion';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useUI } from '../context/UIContext';
import { useRecentlyViewed } from '../hooks/useRecentlyViewed';
import { cn } from '../lib/cn';
import { date, deliveryDate, discountPct, price, sized } from '../lib/format';
import NotFound from './NotFound';

function Gallery({ images, name, imgRef }) {
  const [active, setActive] = useState(0);
  const [zoom, setZoom] = useState(null);
  const img = images[active];

  return (
    <div className="flex flex-col-reverse gap-3 md:flex-row">
      {images.length > 1 && (
        <div className="no-scrollbar flex gap-2 overflow-x-auto md:flex-col">
          {images.map((im, i) => (
            <button key={im.id} onClick={() => setActive(i)} aria-label={`Image ${i + 1}`}
              className="relative h-20 w-16 shrink-0 overflow-hidden rounded-xl bg-muted">
              <img src={sized(im.image_url, 160)} alt="" className="h-full w-full object-cover" />
              {i === active && <motion.span layoutId="thumb-ring" className="absolute inset-0 rounded-xl ring-2 ring-inset ring-brand" />}
            </button>
          ))}
        </div>
      )}
      <div
        className="relative aspect-[4/5] flex-1 cursor-zoom-in overflow-hidden rounded-3xl bg-muted"
        onMouseMove={(e) => {
          const r = e.currentTarget.getBoundingClientRect();
          setZoom({ x: ((e.clientX - r.left) / r.width) * 100, y: ((e.clientY - r.top) / r.height) * 100 });
        }}
        onMouseLeave={() => setZoom(null)}
      >
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.img
            key={img?.id} ref={imgRef} src={sized(img?.image_url, 1200)} alt={name}
            initial={{ opacity: 0, scale: 1.04 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.45, ease }}
            drag={images.length > 1 ? 'x' : false} dragConstraints={{ left: 0, right: 0 }} dragElastic={0.3}
            onDragEnd={(_, info) => {
              if (info.offset.x < -60) setActive((a) => Math.min(a + 1, images.length - 1));
              if (info.offset.x > 60) setActive((a) => Math.max(a - 1, 0));
            }}
            className="absolute inset-0 h-full w-full object-cover transition-transform duration-200"
            style={zoom ? { transform: 'scale(1.9)', transformOrigin: `${zoom.x}% ${zoom.y}%` } : undefined}
          />
        </AnimatePresence>
        {images.length > 1 && (
          <div className="absolute bottom-4 left-1/2 flex -translate-x-1/2 gap-1.5 md:hidden">
            {images.map((_, i) => <span key={i} className={cn('h-1.5 rounded-full bg-white transition-all', i === active ? 'w-5' : 'w-1.5 opacity-60')} />)}
          </div>
        )}
      </div>
    </div>
  );
}

function DeliveryCheck() {
  const [pin, setPin] = useState('');
  const [result, setResult] = useState(null);
  const check = (e) => {
    e.preventDefault();
    if (!/^[1-9]\d{5}$/.test(pin)) return setResult({ ok: false });
    const metro = ['11', '40', '56', '60', '70', '50'].includes(pin.slice(0, 2));
    setResult({ ok: true, date: deliveryDate(metro ? 2 : 4) });
  };
  return (
    <div className="card p-4">
      <form onSubmit={check} className="flex items-center gap-2">
        <MapPin size={18} className="shrink-0 text-ink-faint" />
        <input value={pin} onChange={(e) => setPin(e.target.value.replace(/\D/g, '').slice(0, 6))} inputMode="numeric"
          placeholder="Enter delivery pincode" className="h-9 flex-1 bg-transparent text-sm outline-none" aria-label="Pincode" />
        <button className="text-sm font-semibold text-brand">Check</button>
      </form>
      <AnimatePresence mode="wait">
        {result && (
          <motion.p key={JSON.stringify(result)} initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }}
            className={cn('mt-2 border-t border-line pt-2 text-sm', result.ok ? 'text-success' : 'text-danger')}>
            {result.ok ? <>Delivery by <b>{result.date}</b> · Free above ₹499</> : 'Please enter a valid 6-digit pincode'}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}

function Reviews({ product }) {
  const { user } = useAuth();
  const qc = useQueryClient();
  const { data } = useQuery({ queryKey: ['reviews', product.id, !!user], queryFn: () => catalogApi.reviews(product.id) });
  const [form, setForm] = useState({ rating: 0, title: '', comment: '' });
  const [hover, setHover] = useState(0);
  const submit = useMutation({
    mutationFn: () => catalogApi.addReview(product.id, form),
    onSuccess: () => {
      toast.success('Thanks for your review!');
      setForm({ rating: 0, title: '', comment: '' });
      qc.invalidateQueries({ queryKey: ['reviews', product.id] });
      qc.invalidateQueries({ queryKey: ['product', product.slug] });
    },
    onError: (e) => toast.error(errorMessage(e)),
  });
  if (!data) return <Skeleton className="h-40" />;

  return (
    <div className="grid gap-10 lg:grid-cols-[300px_1fr]">
      <div>
        <div className="flex items-end gap-3">
          <span className="font-display text-6xl font-extrabold">{data.average.toFixed(1)}</span>
          <div className="pb-2"><Stars value={data.average} size={18} /><p className="mt-1 text-sm text-ink-faint">{data.count} reviews</p></div>
        </div>
        <div className="mt-6 space-y-2">
          {[5, 4, 3, 2, 1].map((s) => {
            const pct = data.count ? (data.distribution[s] / data.count) * 100 : 0;
            return (
              <div key={s} className="flex items-center gap-3 text-sm">
                <span className="w-3 text-ink-soft">{s}</span>
                <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
                  <motion.div className="h-full rounded-full bg-amber-400" initial={{ width: 0 }} whileInView={{ width: `${pct}%` }}
                    viewport={{ once: true }} transition={{ duration: 0.9, ease, delay: (5 - s) * 0.08 }} />
                </div>
                <span className="w-8 text-right text-xs text-ink-faint">{data.distribution[s]}</span>
              </div>
            );
          })}
        </div>

        {data.can_review && (
          <form className="card mt-8 space-y-3 p-5" onSubmit={(e) => { e.preventDefault(); if (!form.rating) return toast.error('Please pick a star rating'); submit.mutate(); }}>
            <p className="font-semibold">Write a review</p>
            <div className="flex gap-1" onMouseLeave={() => setHover(0)}>
              {[1, 2, 3, 4, 5].map((s) => (
                <motion.button key={s} type="button" whileHover={{ scale: 1.2 }} whileTap={{ scale: 0.9 }}
                  onMouseEnter={() => setHover(s)} onClick={() => setForm({ ...form, rating: s })} aria-label={`${s} stars`}>
                  <svg viewBox="0 0 24 24" className={cn('h-7 w-7 transition', (hover || form.rating) >= s ? 'text-amber-400' : 'text-line')} fill="currentColor">
                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z" />
                  </svg>
                </motion.button>
              ))}
            </div>
            <input className="input" placeholder="Title (optional)" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            <textarea className="input h-24 py-3" placeholder="What did you like or dislike?" value={form.comment} onChange={(e) => setForm({ ...form, comment: e.target.value })} />
            <button className="btn-dark w-full" disabled={submit.isPending}>{submit.isPending ? 'Posting…' : 'Post review'}</button>
          </form>
        )}
        {!user && <p className="mt-6 text-sm text-ink-soft"><Link to="/login" className="font-semibold text-brand">Sign in</Link> to write a review.</p>}
      </div>

      <div className="divide-y divide-line">
        {data.reviews.length === 0 && <p className="py-6 text-ink-soft">No reviews yet — be the first to share your thoughts.</p>}
        {data.reviews.map((r, i) => (
          <motion.article key={r.id} initial={{ opacity: 0, y: 12 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }}
            transition={{ delay: Math.min(i, 5) * 0.05 }} className="py-5 first:pt-0">
            <div className="flex items-center gap-3">
              <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-soft text-xs font-bold text-brand">{r.user_name[0]}</span>
              <div>
                <p className="text-sm font-semibold">{r.user_name}</p>
                <p className="flex items-center gap-2 text-xs text-ink-faint">
                  {date(r.created_at)}
                  {r.is_verified_purchase && <span className="inline-flex items-center gap-1 text-success"><BadgeCheck size={13} /> Verified purchase</span>}
                </p>
              </div>
            </div>
            <div className="mt-3 flex items-center gap-2"><Stars value={r.rating} />{r.title && <p className="text-sm font-semibold">{r.title}</p>}</div>
            {r.comment && <p className="mt-2 text-sm leading-relaxed text-ink-soft">{r.comment}</p>}
          </motion.article>
        ))}
      </div>
    </div>
  );
}

const TABS = ['Description', 'Specifications', 'Reviews'];

export default function ProductDetail() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const { add, busy } = useCart();
  const { flyToCart, setCartOpen } = useUI();
  const { push } = useRecentlyViewed();
  const [qty, setQty] = useState(1);
  const [tab, setTab] = useState('Description');
  const [added, setAdded] = useState(false);
  const imgRef = useRef(null);
  const buyRef = useRef(null);
  const [showSticky, setShowSticky] = useState(false);

  const { data: product, isLoading, isError } = useQuery({ queryKey: ['product', slug], queryFn: () => catalogApi.product(slug) });
  const { data: related = [] } = useQuery({ queryKey: ['related', slug], queryFn: () => catalogApi.related(slug), enabled: !!product });

  useEffect(() => { if (product) { push(product); setQty(1); document.title = `${product.name} — NirmalMart`; } }, [product?.id]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    const el = buyRef.current;
    if (!el) return;
    const io = new IntersectionObserver(([e]) => setShowSticky(!e.isIntersecting && e.boundingClientRect.top < 0));
    io.observe(el);
    return () => io.disconnect();
  }, [product?.id]);

  if (isError) return <NotFound />;
  if (isLoading) {
    return (
      <div className="container grid gap-10 py-10 lg:grid-cols-2">
        <Skeleton className="aspect-[4/5] rounded-3xl" />
        <div className="space-y-4"><Skeleton className="h-4 w-24" /><Skeleton className="h-10 w-3/4" /><Skeleton className="h-6 w-40" /><Skeleton className="h-32" /></div>
      </div>
    );
  }

  const off = discountPct(product.price, product.compare_at_price);
  const soldOut = product.stock_quantity <= 0;
  const low = !soldOut && product.stock_quantity <= 10;
  const maxQty = Math.min(20, product.stock_quantity);

  const addToBag = async () => {
    if (await add(product, qty)) {
      flyToCart(imgRef.current);
      setAdded(true);
      setTimeout(() => setAdded(false), 1800);
    }
  };
  const buyNow = async () => { if (await add(product, qty)) navigate('/checkout'); };
  const share = async () => {
    try {
      if (navigator.share) await navigator.share({ title: product.name, url: location.href });
      else { await navigator.clipboard.writeText(location.href); toast.success('Link copied'); }
    } catch { /* user cancelled */ }
  };

  return (
    <>
      <div className="container pb-6 pt-6">
        <nav className="mb-6 flex flex-wrap items-center gap-1 text-xs text-ink-faint" aria-label="Breadcrumb">
          <Link to="/" className="hover:text-ink">Home</Link><ChevronRight size={12} />
          {product.category && <><Link to={`/shop?category=${product.category.slug}`} className="hover:text-ink">{product.category.name}</Link><ChevronRight size={12} /></>}
          <span className="line-clamp-1 text-ink">{product.name}</span>
        </nav>

        <div className="grid gap-10 lg:grid-cols-[1.1fr_1fr] lg:gap-14">
          <div className="relative lg:sticky lg:top-28 lg:self-start">
            <HeartButton product={product} className="absolute right-3 top-3 z-10 sm:hidden" />
            <Gallery images={product.images.length ? product.images : [{ id: 0, image_url: '' }]} name={product.name} imgRef={imgRef} />
          </div>

          <motion.div initial="hidden" animate="show" variants={{ show: { transition: { staggerChildren: 0.06 } } }}>
            {[
              product.brand && <Link key="b" to={`/shop?search=${encodeURIComponent(product.brand)}`} className="text-xs font-bold uppercase tracking-[0.15em] text-brand hover:underline">{product.brand}</Link>,
              <h1 key="h" className="mt-2 font-display text-3xl font-extrabold leading-tight sm:text-4xl">{product.name}</h1>,
              <button key="r" onClick={() => { setTab('Reviews'); document.getElementById('details')?.scrollIntoView({ behavior: 'smooth' }); }}
                className="mt-3 flex items-center gap-2 text-sm text-ink-soft hover:text-ink">
                <Stars value={Number(product.rating_avg)} /> <b className="text-ink">{Number(product.rating_avg).toFixed(1)}</b> · {product.rating_count} reviews · {product.sold_count}+ sold
              </button>,
              <div key="p" className="mt-6">
                <Price value={product.price} mrp={product.compare_at_price} size="xl" />
                <p className="mt-1 text-xs text-ink-faint">Inclusive of all taxes{off > 0 && <> · You save <b className="text-success">{price(product.compare_at_price - product.price)}</b></>}</p>
              </div>,
              <div key="s" className="mt-5">
                {soldOut ? <span className="badge bg-danger/10 text-danger">Out of stock</span>
                  : low ? (
                    <span className="inline-flex items-center gap-2 text-sm font-semibold text-deal">
                      <span className="relative flex h-2 w-2"><span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-deal opacity-75" /><span className="relative h-2 w-2 rounded-full bg-deal" /></span>
                      Hurry — only {product.stock_quantity} left
                    </span>
                  ) : <span className="inline-flex items-center gap-2 text-sm font-medium text-success"><Check size={16} /> In stock, ready to ship</span>}
              </div>,
              product.highlights?.length > 0 && (
                <ul key="hl" className="mt-6 space-y-2.5">
                  {product.highlights.map((h) => (
                    <li key={h} className="flex gap-3 text-sm text-ink-soft"><span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-brand" />{h}</li>
                  ))}
                </ul>
              ),
              <div key="buy" ref={buyRef} className="mt-8 flex flex-wrap items-center gap-3">
                {!soldOut && <Qty value={qty} max={maxQty} onChange={(q) => setQty(Math.max(1, Math.min(maxQty, q)))} />}
                <motion.button whileTap={{ scale: 0.97 }} onClick={addToBag} disabled={soldOut || busy} className="btn-dark btn-lg flex-1">
                  <AnimatePresence mode="wait" initial={false}>
                    <motion.span key={String(added)} className="flex items-center gap-2" initial={{ y: 14, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -14, opacity: 0 }}>
                      {added ? <><Check size={18} /> Added to bag</> : <><ShoppingBag size={18} /> Add to bag</>}
                    </motion.span>
                  </AnimatePresence>
                </motion.button>
                <HeartButton product={product} className="relative hidden h-13 w-13 border border-line shadow-none sm:grid" />
                <button onClick={share} className="btn-icon hidden h-13 w-13 border border-line sm:inline-flex" aria-label="Share"><Share2 size={18} /></button>
              </div>,
              !soldOut && (
                <motion.button key="now" whileTap={{ scale: 0.98 }} onClick={buyNow} className="btn-primary btn-lg mt-3 w-full">
                  <Zap size={18} /> Buy now
                </motion.button>
              ),
              added && (
                <motion.button key="view" initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={() => setCartOpen(true)} className="mt-3 w-full text-center text-sm font-semibold text-brand">
                  View bag →
                </motion.button>
              ),
              <div key="del" className="mt-8 space-y-3">
                <DeliveryCheck />
                <div className="grid grid-cols-3 gap-2 text-center text-xs text-ink-soft">
                  {[[Truck, 'Free delivery above ₹499'], [RotateCcw, '7-day easy returns'], [ShieldCheck, 'Secure checkout']].map(([Icon, t]) => (
                    <div key={t} className="rounded-2xl bg-muted px-2 py-3"><Icon size={18} className="mx-auto mb-1.5 text-ink" />{t}</div>
                  ))}
                </div>
              </div>,
            ].filter(Boolean).map((el) => <motion.div key={el.key} variants={{ hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0, transition: { duration: 0.5, ease } } }}>{el}</motion.div>)}
          </motion.div>
        </div>

        <section id="details" className="mt-20 scroll-mt-28">
          <div className="flex gap-6 border-b border-line">
            {TABS.map((t) => (
              <button key={t} onClick={() => setTab(t)} className={cn('relative pb-3 text-sm font-semibold transition', tab === t ? 'text-ink' : 'text-ink-faint hover:text-ink')}>
                {t}{t === 'Reviews' && ` (${product.rating_count})`}
                {tab === t && <motion.span layoutId="pd-tab" className="absolute inset-x-0 -bottom-px h-0.5 rounded-full bg-ink" />}
              </button>
            ))}
          </div>
          <AnimatePresence mode="wait">
            <motion.div key={tab} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} transition={{ duration: 0.25 }} className="py-8">
              {tab === 'Description' && (
                <div className="max-w-3xl space-y-4 text-[15px] leading-relaxed text-ink-soft">
                  {(product.description || '').split('\n').filter(Boolean).map((p, i) => <p key={i}>{p}</p>)}
                  <p className="flex items-center gap-2 pt-2 text-sm"><PackageCheck size={16} className="text-success" /> SKU: {product.sku}</p>
                </div>
              )}
              {tab === 'Specifications' && (
                <dl className="max-w-2xl overflow-hidden rounded-2xl border border-line">
                  {Object.entries(product.specifications || {}).map(([k, v], i) => (
                    <div key={k} className={cn('grid grid-cols-[160px_1fr] gap-4 px-5 py-3.5 text-sm', i % 2 === 0 && 'bg-muted/60')}>
                      <dt className="text-ink-faint">{k}</dt><dd className="font-medium">{v}</dd>
                    </div>
                  ))}
                  {!Object.keys(product.specifications || {}).length && <p className="p-5 text-sm text-ink-faint">No specifications listed.</p>}
                </dl>
              )}
              {tab === 'Reviews' && <Reviews product={product} />}
            </motion.div>
          </AnimatePresence>
        </section>
      </div>

      <ProductRail eyebrow="You may also like" title="Similar products" products={related} />

      <AnimatePresence>
        {showSticky && !soldOut && (
          <motion.div initial={{ y: 100 }} animate={{ y: 0 }} exit={{ y: 100 }} transition={{ type: 'spring', damping: 26, stiffness: 300 }}
            className="fixed inset-x-0 bottom-0 z-30 border-t border-line bg-surface/90 backdrop-blur-xl">
            <div className="container flex items-center gap-3 py-3">
              <img src={sized(product.images[0]?.image_url, 120)} alt="" className="hidden h-12 w-12 rounded-xl object-cover sm:block" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{product.name}</p>
                <p className="text-sm font-bold">{price(product.price)}</p>
              </div>
              <button onClick={addToBag} className="btn-dark"><ShoppingBag size={16} /> Add</button>
              <button onClick={buyNow} className="btn-primary hidden sm:inline-flex">Buy now</button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
