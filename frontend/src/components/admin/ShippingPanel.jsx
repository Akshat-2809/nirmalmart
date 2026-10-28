import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowUpRight, FileDown, PackageCheck, RefreshCw, Truck } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { cn } from '../../lib/cn';
import { price } from '../../lib/format';
import { store } from '../../lib/storage';
import { Spinner } from '../ui/bits';

const PARCEL_KEY = 'nm-last-parcel';
const DEFAULT_PARCEL = { weight: 0.5, length: 20, breadth: 15, height: 10 };
const FIELDS = [['weight', 'Weight', 'kg', 0.05], ['length', 'Length', 'cm', 1], ['breadth', 'Breadth', 'cm', 1], ['height', 'Height', 'cm', 1]];

function Note({ children, tone = 'muted' }) {
  return <p className={cn('rounded-xl p-3 text-xs leading-relaxed', tone === 'warn' ? 'bg-warning/10 text-ink-soft' : 'bg-muted text-ink-soft')}>{children}</p>;
}

/** Shiprocket controls inside the admin order drawer: book a courier, then label / track / cancel. */
export default function ShippingPanel({ order, onChange }) {
  const qc = useQueryClient();
  const { data: conn, isPending: connLoading } = useQuery({ queryKey: ['admin', 'shipping'], queryFn: adminApi.shippingStatus, staleTime: 5 * 60_000 });
  const [parcel, setParcel] = useState(() => ({ ...DEFAULT_PARCEL, ...store.get(PARCEL_KEY, {}) }));
  const [cod, setCod] = useState(order.payment_status !== 'paid');
  const [courier, setCourier] = useState(null);   // null = Shiprocket's recommended courier

  const done = (msg) => (o) => { onChange(o); qc.invalidateQueries({ queryKey: ['admin', 'orders'] }); if (msg) toast.success(msg); };
  const fail = (e) => toast.error(errorMessage(e));
  const options = useMutation({ mutationFn: () => adminApi.couriers(order.id, parcel.weight, cod), onError: fail });
  const ship = useMutation({
    mutationFn: () => { store.set(PARCEL_KEY, parcel); return adminApi.shipOrder(order.id, { ...parcel, cod, courier_id: courier }); },
    onSuccess: done('Courier booked'), onError: fail,
  });
  const label = useMutation({ mutationFn: () => adminApi.shipmentLabel(order.id), onSuccess: done('Label ready'), onError: fail });
  const refresh = useMutation({ mutationFn: () => adminApi.refreshShipment(order.id), onSuccess: done('Tracking updated'), onError: fail });
  const cancel = useMutation({ mutationFn: () => adminApi.cancelShipment(order.id), onSuccess: done('Shipment cancelled'), onError: fail });

  const heading = <p className="flex items-center gap-1.5 text-xs uppercase tracking-wider text-ink-faint"><Truck size={14} /> Shipping · Shiprocket</p>;

  if (order.awb_code) {
    const busy = label.isPending || refresh.isPending || cancel.isPending;
    return (
      <div className="space-y-3">
        {heading}
        <div className="rounded-2xl border border-line p-4">
          <p className="font-semibold">{order.courier_name || 'Courier'} · AWB {order.awb_code}</p>
          <p className="mt-0.5 text-ink-soft">{order.tracking_status || 'Booked'}</p>
          <div className="mt-3 flex flex-wrap gap-2">
            {order.shipping_label_url
              ? <a href={order.shipping_label_url} target="_blank" rel="noopener noreferrer" className="btn-primary btn-sm"><FileDown size={14} /> Label</a>
              : <button className="btn-primary btn-sm" disabled={busy} onClick={() => label.mutate()}>{label.isPending ? <Spinner /> : <FileDown size={14} />} Get label</button>}
            <a href={order.tracking_url} target="_blank" rel="noopener noreferrer" className="btn-outline btn-sm">Track <ArrowUpRight size={14} /></a>
            <button className="btn-outline btn-sm" disabled={busy} onClick={() => refresh.mutate()}>
              <RefreshCw size={14} className={cn(refresh.isPending && 'animate-spin')} /> Update
            </button>
            {!['shipped', 'delivered'].includes(order.status) && (
              <button className="btn-ghost btn-sm text-danger hover:bg-danger/10 hover:text-danger" disabled={busy}
                onClick={() => window.confirm('Cancel this courier booking? The order stays open so you can ship it again.') && cancel.mutate()}>Cancel shipment</button>
            )}
          </div>
        </div>
      </div>
    );
  }

  if (connLoading) return <div className="space-y-3">{heading}<div className="skeleton h-20 rounded-2xl" /></div>;
  if (!conn?.configured) {
    return <div className="space-y-3">{heading}<Note>Shiprocket isn’t connected yet. Until it is, pack the order yourself and use “Mark shipped”.</Note></div>;
  }
  if (!conn.connected) {
    return <div className="space-y-3">{heading}<Note tone="warn">Couldn’t reach Shiprocket: {conn.error}</Note></div>;
  }
  if (['shipped', 'delivered', 'cancelled'].includes(order.status)) return null;
  if (order.status === 'pending') {
    return <div className="space-y-3">{heading}<Note>Confirm the order first, then book a courier here.</Note></div>;
  }

  const couriers = options.data?.couriers;
  return (
    <div className="space-y-3">
      {heading}
      {order.tracking_status === 'SHIPMENT CANCELLED' && <Note>The previous courier booking was cancelled. You can book again.</Note>}
      <div className="rounded-2xl border border-line p-4">
        <p className="text-xs font-semibold text-ink-soft">Parcel (packed box)</p>
        <div className="mt-2 grid grid-cols-4 gap-2">
          {FIELDS.map(([k, label, unit, step]) => (
            <label key={k} className="text-xs text-ink-faint">
              {label} <span className="text-ink-faint/70">({unit})</span>
              <input type="number" min={step} step={step} value={parcel[k]} className="input mt-1 h-10 px-2 text-sm"
                onChange={(e) => { setParcel({ ...parcel, [k]: Number(e.target.value) }); options.reset(); }} />
            </label>
          ))}
        </div>

        <p className="mt-4 text-xs font-semibold text-ink-soft">Payment</p>
        <div className="mt-2 grid grid-cols-2 gap-2">
          {[[false, 'Prepaid', 'Customer has paid'], [true, 'Cash on delivery', `Courier collects ${price(order.total_amount)}`]].map(([v, t, sub]) => (
            <button key={t} type="button" onClick={() => { setCod(v); options.reset(); setCourier(null); }}
              className={cn('rounded-xl border p-2.5 text-left transition', cod === v ? 'border-brand bg-brand-soft' : 'border-line hover:border-ink/30')}>
              <span className="block text-sm font-semibold">{t}</span><span className="block text-[11px] text-ink-soft">{sub}</span>
            </button>
          ))}
        </div>
        {!cod && order.payment_status !== 'paid' && <p className="mt-2 text-xs text-warning">This order isn’t marked paid — choose Prepaid only if you’ve received the money.</p>}

        <div className="mt-4">
          {!couriers ? (
            <button type="button" className="btn-ghost btn-sm -ml-2" disabled={options.isPending || !parcel.weight} onClick={() => options.mutate()}>
              {options.isPending ? <Spinner /> : <PackageCheck size={14} />} Compare couriers & prices
            </button>
          ) : couriers.length === 0 ? (
            <Note tone="warn">No courier delivers to {order.shipping_address?.postal_code}{cod && ' with cash on delivery'}.</Note>
          ) : (
            <div className="space-y-1.5">
              <p className="text-xs font-semibold text-ink-soft">Courier</p>
              {[{ courier_id: null, name: 'Recommended by Shiprocket' }, ...couriers].map((c) => (
                <label key={c.courier_id ?? 'auto'} className={cn('flex cursor-pointer items-center gap-3 rounded-xl border p-2.5 text-sm transition',
                  courier === c.courier_id ? 'border-brand bg-brand-soft' : 'border-line hover:border-ink/30')}>
                  <input type="radio" name="courier" className="accent-[rgb(var(--brand))]" checked={courier === c.courier_id} onChange={() => setCourier(c.courier_id)} />
                  <span className="min-w-0 flex-1">
                    <span className="block font-medium">{c.name}{c.courier_id === options.data.recommended_id && <span className="ml-1.5 text-[11px] font-semibold text-brand">Recommended</span>}</span>
                    {c.days && <span className="block text-[11px] text-ink-faint">{c.days} day{c.days > 1 && 's'}{c.etd && ` · by ${c.etd}`}</span>}
                  </span>
                  {c.rate > 0 && <b>{price(c.rate)}</b>}
                </label>
              ))}
            </div>
          )}
        </div>

        <button type="button" className="btn-primary mt-4 w-full" disabled={ship.isPending || !parcel.weight || couriers?.length === 0} onClick={() => ship.mutate()}>
          {ship.isPending ? <><Spinner /> Booking courier…</> : <><Truck size={16} /> Ship with Shiprocket</>}
        </button>
        <p className="mt-2 text-center text-[11px] text-ink-faint">Pickup from {conn.pickup_location} · charges come from your Shiprocket wallet</p>
      </div>
    </div>
  );
}
