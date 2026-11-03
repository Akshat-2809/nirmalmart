import { useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowUpRight, FileDown, RefreshCw, RotateCcw, Truck } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { adminApi } from '../../api';
import { errorMessage } from '../../api/client';
import { cn } from '../../lib/cn';
import { dateTime, price } from '../../lib/format';
import { store } from '../../lib/storage';
import { Spinner } from '../ui/bits';
import { RETURN_LABELS } from '../order/Returns';

const PARCEL_KEY = 'nm-last-parcel';
const FIELDS = [['weight', 'Weight', 'kg', 0.05], ['length', 'Length', 'cm', 1], ['breadth', 'Breadth', 'cm', 1], ['height', 'Height', 'cm', 1]];

function Parcel({ value, onChange }) {
  return (
    <div className="grid grid-cols-4 gap-2">
      {FIELDS.map(([k, label, unit, step]) => (
        <label key={k} className="text-xs text-ink-faint">
          {label} <span className="text-ink-faint/70">({unit})</span>
          <input type="number" min={step} step={step} value={value[k]} className="input mt-1 h-10 px-2 text-sm"
            onChange={(e) => onChange({ ...value, [k]: Number(e.target.value) })} />
        </label>
      ))}
    </div>
  );
}

function ReturnItem({ order, ret, onChange }) {
  const qc = useQueryClient();
  const [parcel, setParcel] = useState(() => ({ weight: 0.5, length: 20, breadth: 15, height: 10, ...store.get(PARCEL_KEY, {}) }));
  const [ref, setRef] = useState('');
  const act = useMutation({
    mutationFn: ([action, body]) => adminApi.returnAction(order.id, ret.id, action, body),
    onSuccess: (o, [action]) => {
      onChange(o);
      qc.invalidateQueries({ queryKey: ['admin', 'orders'] });
      toast.success({ approve: 'Return pickup booked', reject: 'Request rejected', status: 'Updated', refund: 'Refund recorded', replacement: 'Replacement shipped', refresh: 'Tracking updated' }[action]);
    },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const run = (action, body) => act.mutate([action, body]);
  const withParcel = (action) => { store.set(PARCEL_KEY, parcel); run(action, parcel); };
  const reject = () => {
    const note = window.prompt('Reason for rejecting (the customer will see this):', '');
    if (note !== null) run('reject', { note });
  };
  const s = ret.status;
  const isReturn = ret.kind === 'return';
  const busy = act.isPending;
  const a = order.shipping_address || {};

  return (
    <div className="rounded-2xl border border-line p-4">
      <div className="flex items-center justify-between gap-2">
        <p className="font-semibold">{isReturn ? 'Return' : 'Exchange'} #{ret.id}</p>
        <span className={cn('badge', s === 'completed' ? 'bg-success/10 text-success' : ['rejected', 'cancelled'].includes(s) ? 'bg-danger/10 text-danger' : 'bg-warning/10 text-warning')}>{RETURN_LABELS[s]}</span>
      </div>
      <ul className="mt-2 space-y-0.5">
        {ret.items.map((x) => <li key={x.order_item_id}>{x.quantity} × {x.product_name} <span className="text-ink-faint">({price(x.unit_price)})</span></li>)}
      </ul>
      <p className="mt-2"><span className="text-ink-faint">Reason:</span> {ret.reason}</p>
      {ret.comment && <p className="mt-1 rounded-xl bg-muted/60 p-2.5 text-ink-soft">“{ret.comment}”</p>}
      <p className="mt-1 text-xs text-ink-faint">Requested {dateTime(ret.created_at)}{isReturn && ` · refund ${price(ret.refund_amount)} (delivery charge not refunded)`}</p>
      {s === 'rejected' && ret.admin_note && <p className="mt-2 text-xs text-danger">Rejected: {ret.admin_note}</p>}

      {ret.return_awb && (
        <div className="mt-3 rounded-xl bg-muted/60 p-3">
          <p className="flex items-center gap-1.5 font-medium"><Truck size={14} /> Pickup: {ret.return_courier} · AWB {ret.return_awb}</p>
          {ret.return_tracking && <p className="text-xs capitalize text-ink-soft">{ret.return_tracking.toLowerCase()}</p>}
        </div>
      )}
      {ret.repl_awb && (
        <div className="mt-3 rounded-xl bg-brand-soft p-3">
          <p className="flex items-center gap-1.5 font-medium"><Truck size={14} /> Replacement: {ret.repl_courier} · AWB {ret.repl_awb}</p>
          {ret.repl_tracking && <p className="text-xs capitalize text-ink-soft">{ret.repl_tracking.toLowerCase()}</p>}
        </div>
      )}
      {s === 'completed' && isReturn && <p className="mt-2 text-success">Refunded {dateTime(ret.completed_at)}{ret.refund_reference && ` · ref ${ret.refund_reference}`}</p>}

      {/* Approve: book Shiprocket to collect from the customer */}
      {['requested', 'approved'].includes(s) && (
        <div className="mt-3 space-y-2">
          <p className="text-xs text-ink-soft">Approving books a Shiprocket pickup from {a.city} {a.postal_code} back to your pickup address. Parcel size:</p>
          <Parcel value={parcel} onChange={setParcel} />
          {s === 'approved' && <p className="text-xs text-warning">Approved, but the courier booking didn’t finish. Try again.</p>}
        </div>
      )}
      {/* Exchange: ship the same items again */}
      {!isReturn && ['picked_up', 'received'].includes(s) && (
        <div className="mt-3 space-y-2">
          <p className="text-xs text-ink-soft">Send the replacement free of charge. Parcel size:</p>
          <Parcel value={parcel} onChange={setParcel} />
        </div>
      )}
      {isReturn && ['picked_up', 'received'].includes(s) && (
        <div className="mt-3 space-y-2">
          <p className="text-xs text-ink-soft">Check the item, then send <b className="text-ink">{price(ret.refund_amount)}</b> by UPI to the account the customer paid from and record it.</p>
          <input value={ref} onChange={(e) => setRef(e.target.value)} maxLength={100} placeholder="Refund UPI reference / UTR (optional)" className="input" />
        </div>
      )}

      <div className="mt-3 flex flex-wrap gap-2">
        {['requested', 'approved'].includes(s) && (
          <button disabled={busy || !parcel.weight} onClick={() => withParcel('approve')} className="btn-primary btn-sm">
            {busy ? <Spinner /> : <Truck size={14} />} {s === 'requested' ? 'Approve & book pickup' : 'Book pickup again'}
          </button>
        )}
        {['approved', 'pickup_scheduled'].includes(s) && <button disabled={busy} onClick={() => run('status', { status: 'picked_up' })} className="btn-outline btn-sm">Mark picked up</button>}
        {['approved', 'pickup_scheduled', 'picked_up'].includes(s) && <button disabled={busy} onClick={() => run('status', { status: 'received' })} className="btn-outline btn-sm">Mark received</button>}
        {isReturn && ['picked_up', 'received'].includes(s) && (
          <button disabled={busy} onClick={() => window.confirm(`Confirm you have sent ${price(ret.refund_amount)} back to the customer?`) && run('refund', { reference: ref.trim() || undefined })} className="btn-primary btn-sm">Mark refunded</button>
        )}
        {!isReturn && ['picked_up', 'received'].includes(s) && (
          <button disabled={busy || !parcel.weight} onClick={() => withParcel('replacement')} className="btn-primary btn-sm">{busy ? <Spinner /> : <Truck size={14} />} Ship replacement</button>
        )}
        {ret.return_tracking_url && !['completed', 'rejected', 'cancelled'].includes(s) && <a href={ret.return_tracking_url} target="_blank" rel="noopener noreferrer" className="btn-ghost btn-sm">Track pickup <ArrowUpRight size={14} /></a>}
        {ret.repl_label_url && <a href={ret.repl_label_url} target="_blank" rel="noopener noreferrer" className="btn-primary btn-sm"><FileDown size={14} /> Label</a>}
        {ret.repl_tracking_url && <a href={ret.repl_tracking_url} target="_blank" rel="noopener noreferrer" className="btn-ghost btn-sm">Track replacement <ArrowUpRight size={14} /></a>}
        {(ret.return_awb || ret.repl_awb) && !['rejected', 'cancelled'].includes(s) && <button disabled={busy} onClick={() => run('refresh')} className="btn-ghost btn-sm"><RefreshCw size={14} /> Update</button>}
        {['requested', 'approved', 'pickup_scheduled'].includes(s) && <button disabled={busy} onClick={reject} className="btn-ghost btn-sm text-danger">Reject</button>}
      </div>
    </div>
  );
}

/** Return / exchange requests on an order, inside the admin order drawer */
export default function ReturnsPanel({ order, onChange }) {
  if (!order.returns?.length) return null;
  return (
    <div className="space-y-3">
      <p className="flex items-center gap-1.5 text-xs uppercase tracking-wider text-ink-faint"><RotateCcw size={14} /> Returns & exchanges</p>
      {[...order.returns].reverse().map((r) => <ReturnItem key={r.id} order={order} ret={r} onChange={onChange} />)}
    </div>
  );
}
