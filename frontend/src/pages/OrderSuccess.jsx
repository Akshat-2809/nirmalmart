import { useQuery } from '@tanstack/react-query';
import confetti from 'canvas-confetti';
import { motion } from 'framer-motion';
import { ArrowDown, ArrowRight, Package } from 'lucide-react';
import { useEffect, useRef } from 'react';
import { Link, useParams } from 'react-router-dom';
import { orderApi } from '../api';
import UpiPayment, { awaitingUpi } from '../components/order/UpiPayment';
import { Skeleton } from '../components/ui/bits';
import { ease } from '../components/ui/motion';
import { deliveryDate, price } from '../lib/format';

export default function OrderSuccess() {
  const { id } = useParams();
  const { data: order } = useQuery({ queryKey: ['orders', id], queryFn: () => orderApi.get(id) });
  const payRef = useRef(null);
  const needsPayment = awaitingUpi(order);
  const scrollToPay = () => payRef.current?.scrollIntoView({
    behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start' });

  // Bring the UPI payment panel into view once the success animation has played
  useEffect(() => {
    if (!needsPayment) return;
    const t = setTimeout(scrollToPay, 1400);
    return () => clearTimeout(t);
  }, [needsPayment]);

  useEffect(() => {
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const colors = ['#317239', '#d8ab54', '#46080c', '#4ca35e', '#f3e2b7'];
    const fire = (x, angle) => confetti({ particleCount: 70, spread: 70, startVelocity: 55, origin: { x, y: 0.7 }, angle, colors });
    const t = setTimeout(() => { fire(0.2, 60); fire(0.8, 120); }, 450);
    return () => clearTimeout(t);
  }, []);

  return (
    <div className="container flex flex-col items-center py-16 text-center">
      <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: 'spring', stiffness: 200, damping: 12 }}
        className="grid h-24 w-24 place-items-center rounded-full bg-success text-white shadow-[0_20px_50px_-10px] shadow-success/50">
        <svg viewBox="0 0 24 24" className="h-12 w-12">
          <motion.path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"
            initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.5, delay: 0.3, ease }} />
        </svg>
      </motion.div>
      <motion.h1 initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4, ease }} className="mt-8 font-display text-4xl font-extrabold sm:text-5xl">
        Order placed!
      </motion.h1>
      <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.55 }} className="mt-3 max-w-md text-ink-soft">
        {needsPayment
          ? 'One last step: pay by UPI below and send us the payment proof on WhatsApp.'
          : 'Thank you for shopping with NirmalMart. We’ll send you updates as your order makes its way to you.'}
      </motion.p>
      {needsPayment && (
        <motion.button initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.65 }} onClick={scrollToPay} className="btn-primary btn-lg mt-6">
          Pay {price(order.total_amount)} now <ArrowDown size={18} className="animate-bounce" />
        </motion.button>
      )}

      <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.7, ease }} className="card mt-10 w-full max-w-md p-6 text-left">
        {!order ? <Skeleton className="h-24" /> : (
          <>
            <div className="flex items-center justify-between">
              <div><p className="text-xs text-ink-faint">Order number</p><p className="font-display text-lg font-bold">{order.order_number}</p></div>
              <span className="grid h-11 w-11 place-items-center rounded-2xl bg-brand-soft text-brand"><Package size={20} /></span>
            </div>
            <dl className="mt-5 space-y-2 border-t border-line pt-5 text-sm">
              <div className="flex justify-between"><dt className="text-ink-soft">Items</dt><dd>{order.items.reduce((s, i) => s + i.quantity, 0)}</dd></div>
              <div className="flex justify-between"><dt className="text-ink-soft">Total</dt><dd className="font-semibold">{price(order.total_amount)}</dd></div>
              <div className="flex justify-between"><dt className="text-ink-soft">Expected delivery</dt><dd className="font-semibold text-success">{deliveryDate(4)}</dd></div>
              <div className="flex justify-between"><dt className="text-ink-soft">Payment</dt><dd className="capitalize">{order.payment_status}</dd></div>
            </dl>
          </>
        )}
      </motion.div>
      {needsPayment && (
        <motion.div ref={payRef} initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.8, ease }} className="mt-6 w-full max-w-2xl scroll-mt-28">
          <UpiPayment order={order} />
        </motion.div>
      )}
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.9 }} className="mt-8 flex flex-wrap justify-center gap-3">
        <Link to={`/account/orders/${id}`} className="btn-dark">Track order</Link>
        <Link to="/shop" className="btn-outline group">Continue shopping <ArrowRight size={16} className="transition group-hover:translate-x-1" /></Link>
      </motion.div>
    </div>
  );
}
