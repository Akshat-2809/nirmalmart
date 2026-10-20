import { AnimatePresence, motion } from 'framer-motion';
import { ArrowRight, Lock, ShoppingBag } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { CartLine, FreeShippingMeter } from '../components/layout/CartDrawer';
import { Empty, Skeleton } from '../components/ui/bits';
import { useCart } from '../context/CartContext';
import { price, priceExact } from '../lib/format';

export function OrderSummary({ cart, children }) {
  const savings = cart.items.reduce((s, i) => s + Math.max(0, (i.compare_at_price || 0) - i.product_price) * i.quantity, 0);
  return (
    <div className="card p-6">
      <h2 className="font-display text-lg font-bold">Order summary</h2>
      <dl className="mt-5 space-y-3 text-sm">
        <div className="flex justify-between"><dt className="text-ink-soft">Items ({cart.total_items})</dt><dd className="font-medium">{price(cart.subtotal)}</dd></div>
        {savings > 0 && <div className="flex justify-between text-success"><dt>You save</dt><dd className="font-semibold">−{price(savings)}</dd></div>}
        <div className="flex justify-between"><dt className="text-ink-soft">Delivery</dt><dd className="font-medium">{cart.shipping_amount ? price(cart.shipping_amount) : <span className="text-success">Free</span>}</dd></div>
        <div className="flex justify-between text-xs text-ink-faint"><dt>Includes GST</dt><dd>{priceExact(cart.tax_amount)}</dd></div>
      </dl>
      <div className="mt-5 flex items-baseline justify-between border-t border-line pt-5">
        <span className="font-semibold">Total</span>
        <motion.span key={cart.total_amount} initial={{ scale: 1.1, color: 'rgb(var(--brand))' }} animate={{ scale: 1, color: 'rgb(var(--ink))' }}
          className="font-display text-2xl font-extrabold">{price(cart.total_amount)}</motion.span>
      </div>
      {children}
    </div>
  );
}

export default function Cart() {
  const { cart, ready } = useCart();
  const navigate = useNavigate();

  if (!ready) return <div className="container py-10"><Skeleton className="h-80" /></div>;
  if (!cart.items.length) {
    return (
      <div className="container py-10">
        <Empty icon={ShoppingBag} title="Your bag is empty" text="Explore our bestsellers and find something you’ll love."
          action={<Link to="/shop" className="btn-primary">Start shopping</Link>} />
      </div>
    );
  }
  return (
    <div className="container py-10">
      <h1 className="font-display text-3xl font-extrabold sm:text-4xl">Your bag</h1>
      <p className="mt-1 text-ink-soft">{cart.total_items} item{cart.total_items > 1 && 's'}</p>
      <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_380px]">
        <div>
          <FreeShippingMeter subtotal={cart.subtotal} threshold={cart.free_shipping_threshold} />
          <ul className="mt-2 divide-y divide-line">
            <AnimatePresence initial={false}>{cart.items.map((i) => <CartLine key={i.id} item={i} />)}</AnimatePresence>
          </ul>
        </div>
        <div className="lg:sticky lg:top-32 lg:self-start">
          <OrderSummary cart={cart}>
            <motion.button whileTap={{ scale: 0.98 }} onClick={() => navigate('/checkout')} className="btn-primary btn-lg group mt-6 w-full">
              Checkout <ArrowRight size={18} className="transition group-hover:translate-x-1" />
            </motion.button>
            <p className="mt-3 flex items-center justify-center gap-1.5 text-xs text-ink-faint"><Lock size={12} /> Secure checkout</p>
          </OrderSummary>
          <Link to="/shop" className="mt-4 block text-center text-sm font-semibold text-ink-soft hover:text-ink">Continue shopping</Link>
        </div>
      </div>
    </div>
  );
}
