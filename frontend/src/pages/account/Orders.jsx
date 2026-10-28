import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowLeft, ArrowUpRight, Check, ChevronRight, Package, Truck, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { Link, useParams } from 'react-router-dom';
import { orderApi } from '../../api';
import { errorMessage } from '../../api/client';
import UpiPayment, { awaitingUpi } from '../../components/order/UpiPayment';
import { Empty, Skeleton, StatusBadge } from '../../components/ui/bits';
import { ease, fadeUp, stagger } from '../../components/ui/motion';
import { useCart } from '../../context/CartContext';
import { cn } from '../../lib/cn';
import { date, dateTime, ORDER_STEPS, price, priceExact, sized } from '../../lib/format';

export function Orders() {
  const { data: orders, isPending } = useQuery({ queryKey: ['orders'], queryFn: orderApi.list });
  if (isPending) return <div className="space-y-3">{[1, 2, 3].map((i) => <Skeleton key={i} className="h-28" />)}</div>;
  if (!orders.length) return <Empty icon={Package} title="No orders yet" text="When you place an order, it will show up here." action={<Link to="/shop" className="btn-primary">Start shopping</Link>} />;
  return (
    <motion.div variants={stagger(0.06)} initial="hidden" animate="show" className="space-y-3">
      <h2 className="mb-5 font-display text-xl font-bold">Your orders</h2>
      {orders.map((o) => (
        <motion.div key={o.id} variants={fadeUp}>
          <Link to={`/account/orders/${o.id}`} className="card group flex flex-wrap items-center gap-4 p-4 transition hover:shadow-lift sm:p-5">
            <div className="flex -space-x-3">
              {o.items.slice(0, 3).map((i) => (
                <img key={i.id} src={sized(i.product_image, 120)} alt="" className="h-14 w-14 rounded-xl border-2 border-surface object-cover" />
              ))}
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2"><p className="font-semibold">{o.order_number}</p><StatusBadge status={o.status} />{awaitingUpi(o) && <StatusBadge payment status="pending" />}</div>
              <p className="mt-1 text-sm text-ink-soft">{date(o.created_at)} · {o.items.reduce((s, i) => s + i.quantity, 0)} items · {price(o.total_amount)}</p>
            </div>
            <ChevronRight size={18} className="text-ink-faint transition group-hover:translate-x-1" />
          </Link>
        </motion.div>
      ))}
    </motion.div>
  );
}

function Timeline({ status, createdAt, updatedAt }) {
  if (status === 'cancelled') {
    return <div className="flex items-center gap-3 rounded-2xl bg-danger/10 p-4 text-sm text-danger"><X size={18} /> This order was cancelled on {dateTime(updatedAt)}.</div>;
  }
  const current = ORDER_STEPS.indexOf(status);
  return (
    <ol className="relative grid grid-cols-5">
      <div className="absolute left-[10%] right-[10%] top-4 h-1 rounded-full bg-muted" />
      <motion.div className="absolute left-[10%] top-4 h-1 rounded-full bg-success" initial={{ width: 0 }}
        animate={{ width: `${(current / (ORDER_STEPS.length - 1)) * 80}%` }} transition={{ duration: 1.1, ease, delay: 0.2 }} />
      {ORDER_STEPS.map((s, i) => (
        <li key={s} className="relative flex flex-col items-center text-center">
          <motion.span initial={{ scale: 0.5, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ delay: 0.2 + i * 0.18, type: 'spring' }}
            className={cn('grid h-9 w-9 place-items-center rounded-full border-4 border-surface', i <= current ? 'bg-success text-white' : 'bg-muted text-ink-faint')}>
            {i <= current ? <Check size={15} strokeWidth={3} /> : <span className="h-2 w-2 rounded-full bg-current" />}
          </motion.span>
          <span className={cn('mt-2 text-[10px] font-medium capitalize tracking-tight sm:text-xs sm:tracking-normal', i <= current ? 'text-ink' : 'text-ink-faint')}>{s}</span>
          {i === 0 && <span className="text-[10px] text-ink-faint">{date(createdAt, { day: 'numeric', month: 'short' })}</span>}
        </li>
      ))}
    </ol>
  );
}

export function OrderDetail() {
  const { id } = useParams();
  const qc = useQueryClient();
  const { add } = useCart();
  const { data: o, isPending } = useQuery({ queryKey: ['orders', id], queryFn: () => orderApi.get(id) });
  const cancel = useMutation({
    mutationFn: () => orderApi.cancel(id),
    onSuccess: (data) => { qc.setQueryData(['orders', id], data); qc.invalidateQueries({ queryKey: ['orders'] }); toast.success('Order cancelled'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  if (isPending) return <Skeleton className="h-96" />;
  const a = o.shipping_address || {};

  return (
    <div className="space-y-4">
      <Link to="/account/orders" className="inline-flex items-center gap-1 text-sm font-medium text-ink-soft hover:text-ink"><ArrowLeft size={16} /> All orders</Link>
      <div className="card p-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-xs text-ink-faint">Order placed {dateTime(o.created_at)}</p>
            <h2 className="font-display text-2xl font-bold">{o.order_number}</h2>
          </div>
          <div className="flex gap-2"><StatusBadge status={o.status} /><StatusBadge payment status={o.payment_status} /></div>
        </div>
        <div className="mt-8"><Timeline status={o.status} createdAt={o.created_at} updatedAt={o.updated_at} /></div>
        {o.awb_code && o.status !== 'cancelled' && (
          <div className="mt-6 flex flex-wrap items-center gap-4 rounded-2xl bg-brand-soft p-4 text-sm">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-surface text-brand"><Truck size={19} /></span>
            <div className="min-w-0 flex-1">
              <p className="font-semibold">{o.courier_name || 'Courier'} · AWB {o.awb_code}</p>
              {o.tracking_status && <p className="text-ink-soft capitalize">{o.tracking_status.toLowerCase()}</p>}
            </div>
            <a href={o.tracking_url} target="_blank" rel="noopener noreferrer" className="btn-primary btn-sm">Track package <ArrowUpRight size={14} /></a>
          </div>
        )}
      </div>

      {awaitingUpi(o) && <UpiPayment order={o} />}

      <div className="grid gap-4 lg:grid-cols-[1fr_320px]">
        <div className="card p-6">
          <h3 className="font-semibold">Items</h3>
          <ul className="mt-3 divide-y divide-line">
            {o.items.map((i) => (
              <li key={i.id} className="flex items-center gap-4 py-4">
                <img src={sized(i.product_image, 160)} alt="" className="h-20 w-16 rounded-xl object-cover" />
                <div className="min-w-0 flex-1">
                  {i.product_slug ? <Link to={`/product/${i.product_slug}`} className="line-clamp-2 text-sm font-medium hover:text-brand">{i.product_name}</Link> : <p className="text-sm font-medium">{i.product_name}</p>}
                  <p className="mt-1 text-xs text-ink-faint">Qty {i.quantity} × {price(i.unit_price)}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold">{price(i.subtotal)}</p>
                  {i.product_id && <button onClick={() => add({ id: i.product_id, name: i.product_name, slug: i.product_slug, price: i.unit_price, stock_quantity: 99, images: [{ image_url: i.product_image }] }, 1)}
                    className="mt-1 text-xs font-semibold text-brand hover:underline">Buy again</button>}
                </div>
              </li>
            ))}
          </ul>
        </div>
        <div className="space-y-4">
          <div className="card p-6 text-sm">
            <h3 className="font-semibold">Delivery address</h3>
            <p className="mt-3 font-medium">{a.full_name}</p>
            <p className="mt-1 text-ink-soft">{a.address_line1}{a.address_line2 && `, ${a.address_line2}`}<br />{a.city}, {a.state} – {a.postal_code}</p>
            {a.phone && <p className="mt-1 text-ink-soft">{a.phone}</p>}
          </div>
          <div className="card space-y-2 p-6 text-sm">
            <h3 className="mb-3 font-semibold">Payment summary</h3>
            <div className="flex justify-between"><span className="text-ink-soft">Items</span><span>{price(o.subtotal_amount)}</span></div>
            <div className="flex justify-between"><span className="text-ink-soft">Delivery</span><span>{o.shipping_amount ? price(o.shipping_amount) : 'Free'}</span></div>
            <div className="flex justify-between text-xs text-ink-faint"><span>Includes GST</span><span>{priceExact(o.tax_amount)}</span></div>
            <div className="flex justify-between border-t border-line pt-3 font-display text-lg font-bold"><span>Total</span><span>{price(o.total_amount)}</span></div>
          </div>
          {['pending', 'confirmed'].includes(o.status) && (
            <button className="btn-outline w-full text-danger hover:border-danger" disabled={cancel.isPending}
              onClick={() => window.confirm('Cancel this order?') && cancel.mutate()}>
              {cancel.isPending ? 'Cancelling…' : 'Cancel order'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
