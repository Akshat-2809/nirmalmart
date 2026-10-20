import { motion } from 'framer-motion';
import { Minus, Plus, Star } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useUI } from '../../context/UIContext';
import { cn } from '../../lib/cn';
import { discountPct, price } from '../../lib/format';

/**
 * Brand logo. Exactly one file is downloaded: the light/dark version follows the site theme
 * (`onDark` forces light text for always-dark panels), and <picture> swaps in the compact cart mark
 * on the narrowest phones so the header still fits.
 */
export function Logo({ className, onDark = false, to = '/' }) {
  const { theme } = useUI();
  const dark = onDark || theme === 'dark';
  return (
    <Link to={to} className={cn('group inline-flex shrink-0 items-center', className)} aria-label="Nirmal Mart home">
      <motion.span whileHover={{ y: -1, scale: 1.02 }} transition={{ type: 'spring', stiffness: 400, damping: 20 }} className="inline-flex">
        <picture>
          <source media="(max-width: 379px)" srcSet={dark ? '/logo-mark-dark.svg' : '/logo-mark.svg'} />
          <img src={dark ? '/logo-dark.svg' : '/logo.svg'} alt="Nirmal Mart" width="154" height="35"
            className="h-7 w-auto select-none max-[379px]:h-9 sm:h-9" />
        </picture>
      </motion.span>
    </Link>
  );
}

export function Stars({ value = 0, size = 14, className }) {
  return (
    <span className={cn('inline-flex items-center gap-0.5', className)} aria-label={`${Number(value).toFixed(1)} out of 5`}>
      {[1, 2, 3, 4, 5].map((i) => {
        const fill = Math.max(0, Math.min(1, value - i + 1));
        return (
          <span key={i} className="relative inline-block" style={{ width: size, height: size }}>
            <Star size={size} className="absolute text-line" fill="currentColor" strokeWidth={0} />
            <span className="absolute inset-0 overflow-hidden" style={{ width: `${fill * 100}%` }}>
              <Star size={size} className="text-amber-400" fill="currentColor" strokeWidth={0} />
            </span>
          </span>
        );
      })}
    </span>
  );
}

export function RatingPill({ value, count }) {
  if (!count) return null;
  return (
    <span className="inline-flex items-center gap-1.5 text-xs text-ink-soft">
      <span className="inline-flex items-center gap-0.5 rounded-md bg-success px-1.5 py-0.5 font-semibold text-white">
        {Number(value).toFixed(1)} <Star size={10} fill="currentColor" strokeWidth={0} />
      </span>
      ({count})
    </span>
  );
}

export function Price({ value, mrp, size = 'md', className }) {
  const off = discountPct(value, mrp);
  const big = { sm: 'text-sm', md: 'text-base', lg: 'text-2xl', xl: 'text-3xl sm:text-4xl' }[size];
  return (
    <div className={cn('flex flex-wrap items-baseline gap-x-2 gap-y-0.5', className)}>
      <span className={cn('font-display font-bold text-ink', big)}>{price(value)}</span>
      {off > 0 && (
        <>
          <span className="text-sm text-ink-faint line-through">{price(mrp)}</span>
          <span className="text-sm font-semibold text-success">{off}% off</span>
        </>
      )}
    </div>
  );
}

export function Qty({ value, onChange, max = 20, disabled, size = 'md' }) {
  const h = size === 'sm' ? 'h-8' : 'h-10';
  return (
    <div className={cn('inline-flex items-center rounded-full border border-line bg-surface', h)}>
      <button type="button" className="grid h-full w-9 place-items-center text-ink-soft transition hover:text-ink disabled:opacity-40"
        onClick={() => onChange(value - 1)} disabled={disabled} aria-label="Decrease quantity">
        <Minus size={14} />
      </button>
      <motion.span key={value} initial={{ y: -8, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
        className="w-7 text-center text-sm font-semibold tabular-nums">{value}</motion.span>
      <button type="button" className="grid h-full w-9 place-items-center text-ink-soft transition hover:text-ink disabled:opacity-40"
        onClick={() => onChange(value + 1)} disabled={disabled || value >= max} aria-label="Increase quantity">
        <Plus size={14} />
      </button>
    </div>
  );
}

export function Skeleton({ className }) {
  return <div className={cn('skeleton', className)} />;
}

export function Spinner({ className }) {
  return <span className={cn('inline-block h-4 w-4 animate-spin rounded-full border-2 border-current border-r-transparent', className)} />;
}

export function Empty({ icon: Icon, title, text, action }) {
  return (
    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}
      className="mx-auto flex max-w-sm flex-col items-center py-16 text-center">
      {Icon && (
        <motion.div initial={{ scale: 0.6, rotate: -10 }} animate={{ scale: 1, rotate: 0 }}
          transition={{ type: 'spring', stiffness: 260, damping: 14 }}
          className="mb-5 grid h-20 w-20 place-items-center rounded-3xl bg-brand-soft text-brand">
          <Icon size={34} strokeWidth={1.6} />
        </motion.div>
      )}
      <h3 className="font-display text-xl font-bold">{title}</h3>
      {text && <p className="mt-2 text-sm text-ink-soft">{text}</p>}
      {action && <div className="mt-6">{action}</div>}
    </motion.div>
  );
}

export function StatusBadge({ status, className, payment }) {
  const style = {
    pending: 'bg-warning/10 text-warning', confirmed: 'bg-brand/10 text-brand', processing: 'bg-brand/10 text-brand',
    shipped: 'bg-sky-500/10 text-sky-600 dark:text-sky-400', delivered: 'bg-success/10 text-success',
    cancelled: 'bg-danger/10 text-danger', paid: 'bg-success/10 text-success', failed: 'bg-danger/10 text-danger',
    refunded: 'bg-muted text-ink-soft',
  }[status] || 'bg-muted text-ink-soft';
  return <span className={cn('badge', style, className)}>{payment ? `Payment ${status}` : status}</span>;
}
