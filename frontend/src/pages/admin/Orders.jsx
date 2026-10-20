import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, Search } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { useSearchParams } from 'react-router-dom';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { PageHead } from '../../components/admin/AdminLayout';
import { Skeleton, StatusBadge } from '../../components/ui/bits';
import { Drawer } from '../../components/ui/Drawer';
import { cn } from '../../lib/cn';
import { dateTime, price, priceExact, sized } from '../../lib/format';

const TABS = ['all', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
const NEXT = {
  pending: [['confirmed', 'Confirm order'], ['cancelled', 'Cancel']],
  confirmed: [['processing', 'Start processing'], ['shipped', 'Mark shipped'], ['cancelled', 'Cancel']],
  processing: [['shipped', 'Mark shipped'], ['cancelled', 'Cancel']],
  shipped: [['delivered', 'Mark delivered']],
};

function OrderDrawer({ order, onClose }) {
  const qc = useQueryClient();
  const setStatus = useMutation({
    mutationFn: (status) => adminApi.setOrderStatus(order.id, status),
    onSuccess: (o) => { toast.success(`Order marked ${o.status}`); qc.invalidateQueries({ queryKey: ['admin'] }); onClose(); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const a = order?.shipping_address || {};
  return (
    <Drawer open={!!order} onClose={onClose} title={order?.order_number} width="max-w-lg"
      footer={order && NEXT[order.status] && (
        <div className="flex flex-wrap gap-2">
          {NEXT[order.status].map(([s, label]) => (
            <button key={s} disabled={setStatus.isPending}
              onClick={() => (s !== 'cancelled' || window.confirm('Cancel this order and restock its items?')) && setStatus.mutate(s)}
              className={s === 'cancelled' ? 'btn-outline text-danger' : 'btn-primary flex-1'}>{label}</button>
          ))}
        </div>
      )}>
      {order && (
        <div className="space-y-6 p-6 text-sm">
          <div className="flex gap-2"><StatusBadge status={order.status} /><StatusBadge payment status={order.payment_status} /></div>
          <div><p className="text-xs uppercase tracking-wider text-ink-faint">Customer</p><p className="mt-1 font-semibold">{order.customer_name}</p><p className="text-ink-soft">{order.customer_email}</p></div>
          <div><p className="text-xs uppercase tracking-wider text-ink-faint">Ship to</p>
            <p className="mt-1">{a.full_name} · {a.phone}<br />{a.address_line1}{a.address_line2 && `, ${a.address_line2}`}<br />{a.city}, {a.state} – {a.postal_code}</p></div>
          {order.notes && <div><p className="text-xs uppercase tracking-wider text-ink-faint">Notes</p><p className="mt-1">{order.notes}</p></div>}
          <ul className="divide-y divide-line rounded-2xl border border-line">
            {order.items.map((i) => (
              <li key={i.id} className="flex items-center gap-3 p-3">
                <img src={sized(i.product_image, 100)} alt="" className="h-12 w-12 rounded-lg object-cover" />
                <span className="min-w-0 flex-1"><span className="line-clamp-1">{i.product_name}</span><span className="text-xs text-ink-faint">{i.quantity} × {price(i.unit_price)}</span></span>
                <b>{price(i.subtotal)}</b>
              </li>
            ))}
          </ul>
          <dl className="space-y-1.5">
            <div className="flex justify-between"><dt className="text-ink-soft">Items</dt><dd>{price(order.subtotal_amount)}</dd></div>
            <div className="flex justify-between"><dt className="text-ink-soft">Shipping</dt><dd>{order.shipping_amount ? price(order.shipping_amount) : 'Free'}</dd></div>
            <div className="flex justify-between text-xs text-ink-faint"><dt>GST included</dt><dd>{priceExact(order.tax_amount)}</dd></div>
            <div className="flex justify-between border-t border-line pt-2 text-base font-bold"><dt>Total</dt><dd>{price(order.total_amount)}</dd></div>
          </dl>
          <p className="text-xs text-ink-faint">Placed {dateTime(order.created_at)} · updated {dateTime(order.updated_at)}</p>
        </div>
      )}
    </Drawer>
  );
}

export default function Orders() {
  const [params, setParams] = useSearchParams();
  const status = params.get('status') || 'all';
  const [search, setSearch] = useState('');
  const [q, setQ] = useState('');
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState(null);
  useEffect(() => { const t = setTimeout(() => { setQ(search); setPage(1); }, 250); return () => clearTimeout(t); }, [search]);

  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'orders', status, q, page],
    queryFn: () => adminApi.orders({ status: status === 'all' ? undefined : status, search: q || undefined, page, per_page: 15 }),
    placeholderData: keepPreviousData,
  });

  return (
    <div>
      <PageHead title="Orders" subtitle={data ? `${data.total} orders` : ' '} />
      <div className="no-scrollbar mb-4 flex gap-1 overflow-x-auto">
        {TABS.map((t) => (
          <button key={t} onClick={() => { setParams(t === 'all' ? {} : { status: t }); setPage(1); }}
            className={cn('relative shrink-0 rounded-full px-4 py-2 text-sm font-medium capitalize', status === t ? 'text-bg' : 'text-ink-soft hover:text-ink')}>
            {status === t && <motion.span layoutId="order-tab" className="absolute inset-0 rounded-full bg-ink" transition={{ type: 'spring', stiffness: 400, damping: 32 }} />}
            <span className="relative">{t}</span>
          </button>
        ))}
      </div>
      <div className="relative mb-4 max-w-sm">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-faint" />
        <input className="input pl-10" placeholder="Order number, customer name or email" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      <div className="space-y-2 md:hidden">
        {isLoading ? [...Array(4)].map((_, i) => <Skeleton key={i} className="h-24" />) :
          data.items.length === 0 ? <p className="py-12 text-center text-ink-faint">No orders found</p> :
          data.items.map((o) => (
            <button key={o.id} onClick={() => setOpen(o)} className="card w-full p-4 text-left active:bg-muted/40">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0"><p className="font-semibold">{o.order_number}</p><p className="truncate text-xs text-ink-faint">{o.customer_name} · {dateTime(o.created_at)}</p></div>
                <p className="shrink-0 font-semibold">{price(o.total_amount)}</p>
              </div>
              <div className="mt-3 flex gap-2"><StatusBadge status={o.status} /><StatusBadge payment status={o.payment_status} /></div>
            </button>
          ))}
      </div>

      <div className="card hidden overflow-hidden md:block">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead className="border-b border-line bg-muted/50 text-left text-xs uppercase tracking-wider text-ink-faint">
              <tr><th className="px-4 py-3">Order</th><th className="px-4 py-3">Customer</th><th className="px-4 py-3">Date</th><th className="px-4 py-3">Total</th><th className="px-4 py-3">Status</th><th className="px-4 py-3">Payment</th></tr>
            </thead>
            <tbody className="divide-y divide-line">
              {isLoading ? [...Array(6)].map((_, i) => <tr key={i}><td colSpan={6} className="px-4 py-3"><Skeleton className="h-8" /></td></tr>) :
                data.items.length === 0 ? <tr><td colSpan={6} className="px-4 py-12 text-center text-ink-faint">No orders found</td></tr> :
                data.items.map((o, i) => (
                  <motion.tr key={o.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.02 }}
                    onClick={() => setOpen(o)} className="cursor-pointer transition hover:bg-muted/40">
                    <td className="px-4 py-3 font-semibold">{o.order_number}<span className="block text-xs font-normal text-ink-faint">{o.items.reduce((s, x) => s + x.quantity, 0)} items</span></td>
                    <td className="px-4 py-3">{o.customer_name}<span className="block text-xs text-ink-faint">{o.customer_email}</span></td>
                    <td className="px-4 py-3 text-ink-soft">{dateTime(o.created_at)}</td>
                    <td className="px-4 py-3 font-semibold">{price(o.total_amount)}</td>
                    <td className="px-4 py-3"><StatusBadge status={o.status} /></td>
                    <td className="px-4 py-3"><StatusBadge status={o.payment_status} /></td>
                  </motion.tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
      {data && data.pages > 1 && (
        <div className="mt-3 flex items-center justify-between text-sm">
          <span className="text-ink-faint">Page {page} of {data.pages}</span>
          <div className="flex gap-1">
            <button className="btn-icon h-9 w-9 border border-line" disabled={page === 1} onClick={() => setPage(page - 1)} aria-label="Previous page"><ChevronLeft size={16} /></button>
            <button className="btn-icon h-9 w-9 border border-line" disabled={page === data.pages} onClick={() => setPage(page + 1)} aria-label="Next page"><ChevronRight size={16} /></button>
          </div>
        </div>
      )}
      <OrderDrawer order={open} onClose={() => setOpen(null)} />
    </div>
  );
}
