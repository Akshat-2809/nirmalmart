import { AnimatePresence, motion } from 'framer-motion';
import { Heart, Plus, Check } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { useRef, useState } from 'react';
import { catalogApi } from '../../api';
import { Link } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { useUI } from '../../context/UIContext';
import { useWishlist } from '../../context/WishlistContext';
import { cn } from '../../lib/cn';
import { discountPct, sized } from '../../lib/format';
import { fadeUp } from '../ui/motion';
import { Price, RatingPill } from '../ui/bits';

export function HeartButton({ product, className }) {
  const { has, toggle } = useWishlist();
  const on = has(product.id);
  return (
    <motion.button
      type="button" whileTap={{ scale: 0.8 }}
      onClick={(e) => { e.preventDefault(); e.stopPropagation(); toggle(product); }}
      className={cn('grid h-9 w-9 place-items-center rounded-full bg-surface/90 shadow-soft backdrop-blur transition hover:scale-110', className || 'relative')}
      aria-label={on ? 'Remove from wishlist' : 'Add to wishlist'} aria-pressed={on}
    >
      <motion.span key={String(on)} initial={{ scale: on ? 0.3 : 1 }} animate={{ scale: 1 }}
        transition={{ type: 'spring', stiffness: 500, damping: 12 }}>
        <Heart size={17} className={on ? 'text-deal' : 'text-ink-soft'} fill={on ? 'currentColor' : 'none'} />
      </motion.span>
      <AnimatePresence>
        {on && (
          <motion.span className="pointer-events-none absolute inset-0 rounded-full border-2 border-deal"
            initial={{ scale: 0.6, opacity: 1 }} animate={{ scale: 1.8, opacity: 0 }} exit={{ opacity: 0 }}
            transition={{ duration: 0.5 }} />
        )}
      </AnimatePresence>
    </motion.button>
  );
}

export default function ProductCard({ product, className }) {
  const { add } = useCart();
  const { flyToCart } = useUI();
  const qc = useQueryClient();
  // Start loading the product page as soon as the shopper shows intent, so it opens instantly
  const prefetch = () => {
    qc.prefetchQuery({ queryKey: ['product', product.slug], queryFn: () => catalogApi.product(product.slug), staleTime: 60_000 });
    const full = product.images?.[0]?.image_url;
    if (full) { const i = new Image(); i.src = sized(full, 1200); }
  };
  const imgRef = useRef(null);
  const [added, setAdded] = useState(false);
  const [first, second] = product.images || [];
  const off = discountPct(product.price, product.compare_at_price);
  const soldOut = product.stock_quantity <= 0;

  const quickAdd = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (await add(product, 1)) {
      flyToCart(imgRef.current);
      setAdded(true);
      setTimeout(() => setAdded(false), 1400);
    }
  };

  return (
    <motion.article variants={fadeUp} className={cn('group relative', className)}>
      <Link to={`/product/${product.slug}`} className="block" onMouseEnter={prefetch} onTouchStart={prefetch} onFocus={prefetch}>
        <div className="relative aspect-square overflow-hidden rounded-2xl bg-muted">
          {first && (
            <img ref={imgRef} src={sized(first.image_url, 600)} alt={product.name} loading="lazy"
              className={cn('h-full w-full object-cover transition duration-700 ease-out group-hover:scale-[1.06]',
                second && 'group-hover:opacity-0')} />
          )}
          {second && (
            <img src={sized(second.image_url, 600)} alt="" loading="lazy" aria-hidden
              className="absolute inset-0 h-full w-full scale-105 object-cover opacity-0 transition duration-700 ease-out group-hover:scale-100 group-hover:opacity-100" />
          )}

          <div className="absolute left-3 top-3 flex flex-col items-start gap-1.5">
            {off >= 30 && <span className="badge bg-deal text-white shadow-sm">-{off}%</span>}
            {product.is_featured && <span className="badge bg-surface/90 text-ink backdrop-blur">Bestseller</span>}
          </div>
          <HeartButton product={product} className="absolute right-3 top-3" />

          {soldOut ? (
            <div className="absolute inset-x-3 bottom-3 rounded-full bg-surface/90 py-2 text-center text-xs font-semibold text-ink-soft backdrop-blur">
              Out of stock
            </div>
          ) : (
            <motion.button
              type="button" onClick={quickAdd} whileTap={{ scale: 0.95 }}
              className="absolute inset-x-3 bottom-3 flex h-11 items-center justify-center gap-2 rounded-full bg-ink/90 text-sm font-semibold text-bg backdrop-blur transition duration-300 ease-out sm:translate-y-[130%] sm:group-hover:translate-y-0 sm:group-focus-within:translate-y-0"
            >
              <AnimatePresence mode="wait" initial={false}>
                {added ? (
                  <motion.span key="ok" className="flex items-center gap-1.5" initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -12, opacity: 0 }}>
                    <Check size={16} /> Added
                  </motion.span>
                ) : (
                  <motion.span key="add" className="flex items-center gap-1.5" initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -12, opacity: 0 }}>
                    <Plus size={16} /> Quick add
                  </motion.span>
                )}
              </AnimatePresence>
            </motion.button>
          )}
        </div>

        <div className="mt-3 space-y-1 px-0.5">
          {product.brand && <p className="text-[11px] font-semibold uppercase tracking-wider text-ink-faint">{product.brand}</p>}
          <h3 className="line-clamp-2 text-sm font-medium leading-snug text-ink transition group-hover:text-brand">{product.name}</h3>
          {product.name_mr && <p lang="mr" className="line-clamp-1 text-[13px] leading-snug text-ink-soft">{product.name_mr}</p>}
          <RatingPill value={product.rating_avg} count={product.rating_count} />
          <Price value={product.price} mrp={product.compare_at_price} size="sm" className="pt-0.5" />
        </div>
      </Link>
    </motion.article>
  );
}

export function ProductCardSkeleton() {
  return (
    <div>
      <div className="skeleton aspect-square rounded-2xl" />
      <div className="mt-3 space-y-2">
        <div className="skeleton h-3 w-16" />
        <div className="skeleton h-4 w-full" />
        <div className="skeleton h-4 w-24" />
      </div>
    </div>
  );
}
