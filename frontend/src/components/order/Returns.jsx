import { useMutation, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowUpRight, Check, Minus, Plus, RefreshCcw, RotateCcw, Undo2 } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { orderApi } from '../../api';
import { errorMessage } from '../../api/client';
import { cn } from '../../lib/cn';
import { date, dateTime, price, sized } from '../../lib/format';

export const RETURN_DAYS = 5;
const REASONS = {
  return: ['Item is damaged or defective', 'Wrong item was sent', 'Parts or accessories missing', 'Quality not as expected', 'Item doesn’t match the description', 'No longer needed'],
  exchange: ['Item is damaged or defective', 'Wrong size', 'Wrong item was sent', 'Parts or accessories missing'],
};
export const RETURN_LABELS = {
  requested: 'Requested', approved: 'Approved', pickup_scheduled: 'Pickup scheduled', picked_up: 'Picked up',
  received: 'Received', completed: 'Completed', rejected: 'Rejected', cancelled: 'Cancelled',
};
export const OPEN_RETURNS = ['requested', 'approved', 'pickup_scheduled', 'picked_up', 'received'];
const CANCELLABLE = ['requested', 'approved', 'pickup_scheduled'];

/** Units of each order item still free to return (not in an active request) */
function available(order) {
  const taken = {};
  for (const r of order.returns || []) {
    if (['rejected', 'cancelled'].includes(r.status)) continue;
    for (const x of r.items) taken[x.order_item_id] = (taken[x.order_item_id] || 0) + x.quantity;
  }
  return Object.fromEntries(order.items.map((i) => [i.id, i.quantity - (taken[i.id] || 0)]));
}

function ReturnForm({ order, left, onDone }) {
  const qc = useQueryClient();
  const [kind, setKind] = useState('return');
  const [qty, setQty] = useState({});      // order_item_id → units chosen
  const [reason, setReason] = useState('');
  const [comment, setComment] = useState('');
  const chosen = Object.entries(qty).filter(([, q]) => q > 0).map(([id, q]) => ({ order_item_id: Number(id), quantity: q }));
  const refund = chosen.reduce((s, x) => s + x.quantity * order.items.find((i) => i.id === x.order_item_id).unit_price, 0);
  const submit = useMutation({
    mutationFn: () => orderApi.requestReturn(order.id, { kind, items: chosen, reason, comment: comment.trim() || undefined }),
    onSuccess: (data) => {
      qc.setQueryData(['orders', String(order.id)], data);
      qc.invalidateQueries({ queryKey: ['orders'] });
      toast.success(kind === 'return' ? 'Return requested' : 'Exchange requested');
      onDone();
    },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const setUnits = (id, n) => setQty({ ...qty, [id]: Math.max(0, Math.min(left[id], n)) });

  return (
    <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="mt-5 space-y-5">
      <div>
        <p className="mb-2 font-semibold">What would you like?</p>
        <div className="grid gap-2 sm:grid-cols-2">
          {[['return', Undo2, 'Return for a refund', 'Money back to your UPI account'], ['exchange', RefreshCcw, 'Exchange', 'The same item again (wrong size or defect)']].map(([k, Icon, t, sub]) => (
            <button key={k} type="button" onClick={() => { setKind(k); setReason(''); }}
              className={cn('flex items-start gap-3 rounded-2xl border-2 p-3 text-left transition', kind === k ? 'border-brand bg-brand-soft/40' : 'border-line hover:border-ink/30')}>
              <Icon size={18} className="mt-0.5 shrink-0 text-brand" />
              <span><span className="block font-semibold">{t}</span><span className="block text-xs text-ink-soft">{sub}</span></span>
            </button>
          ))}
        </div>
      </div>

      <div>
        <p className="mb-2 font-semibold">Which items?</p>
        <ul className="divide-y divide-line rounded-2xl border border-line">
          {order.items.map((i) => {
            const max = left[i.id];
            const n = qty[i.id] || 0;
            return (
              <li key={i.id} className={cn('flex items-center gap-3 p-3', !max && 'opacity-50')}>
                <img src={sized(i.product_image, 120)} alt="" className="h-12 w-12 rounded-lg object-cover" />
                <div className="min-w-0 flex-1">
                  <p className="line-clamp-1 font-medium">{i.product_name}</p>
                  <p className="text-xs text-ink-faint">{max ? `${price(i.unit_price)} each · ${max} can be ${kind === 'return' ? 'returned' : 'exchanged'}` : 'Already in a request'}</p>
                </div>
                {max > 0 && (max === 1 ? (
                  <input type="checkbox" checked={n === 1} onChange={(e) => setUnits(i.id, e.target.checked ? 1 : 0)} className="h-5 w-5 accent-brand" aria-label={`Select ${i.product_name}`} />
                ) : (
                  <div className="flex items-center gap-1">
                    <button type="button" className="btn-icon h-8 w-8" onClick={() => setUnits(i.id, n - 1)} aria-label="Fewer"><Minus size={14} /></button>
                    <span className="w-6 text-center font-semibold">{n}</span>
                    <button type="button" className="btn-icon h-8 w-8" onClick={() => setUnits(i.id, n + 1)} aria-label="More"><Plus size={14} /></button>
                  </div>
                ))}
              </li>
            );
          })}
        </ul>
      </div>

      <div>
        <p className="mb-2 font-semibold">Reason</p>
        <div className="grid gap-2 sm:grid-cols-2">
          {REASONS[kind].map((r) => (
            <label key={r} className={cn('flex cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 transition', reason === r ? 'border-brand bg-brand-soft/40' : 'border-line hover:border-ink/30')}>
              <input type="radio" name="return-reason" checked={reason === r} onChange={() => setReason(r)} className="accent-brand" /> {r}
            </label>
          ))}
        </div>
      </div>

      <div>
        <p className="mb-2 font-semibold">Comments <span className="font-normal text-ink-faint">(optional)</span></p>
        <textarea value={comment} onChange={(e) => setComment(e.target.value)} maxLength={500} placeholder="Tell us what’s wrong, e.g. the switch doesn’t work"
          className="input h-24 py-3" />
        <p className="mt-1 text-right text-[11px] text-ink-faint">{comment.length}/500</p>
      </div>

      <div className="rounded-2xl bg-muted/60 p-4 text-ink-soft">
        <p>Our courier will collect the {chosen.length > 1 ? 'items' : 'item'} from <b className="text-ink">{order.shipping_address?.address_line1}, {order.shipping_address?.city}</b>. Please keep {chosen.length > 1 ? 'them' : 'it'} packed with all parts and tags.</p>
        {kind === 'return'
          ? <p className="mt-2">Refund: <b className="text-ink">{price(refund)}</b> to the UPI account you paid from, once we receive the item. The delivery charge isn’t refunded.</p>
          : <p className="mt-2">We’ll send the same item again at no cost once we receive this one.</p>}
      </div>

      <div className="flex gap-2">
        <button type="button" className="btn-outline flex-1" onClick={onDone} disabled={submit.isPending}>Back</button>
        <button type="button" className="btn-primary flex-1" disabled={!chosen.length || !reason || submit.isPending} onClick={() => submit.mutate()}>
          {submit.isPending ? 'Sending…' : kind === 'return' ? 'Request return' : 'Request exchange'}
        </button>
      </div>
    </motion.div>
  );
}

function Step({ done, current, title, note, last }) {
  return (
    <li className="relative flex gap-3 pb-4 last:pb-0">
      {!last && <span className={cn('absolute left-[11px] top-6 h-[calc(100%-1.25rem)] w-0.5', done ? 'bg-success' : 'bg-muted')} />}
      <span className={cn('grid h-6 w-6 shrink-0 place-items-center rounded-full', done ? 'bg-success text-white' : current ? 'border-2 border-brand bg-surface' : 'border-2 border-line bg-surface')}>
        {done && <Check size={12} strokeWidth={3} />}
      </span>
      <div>
        <p className={cn('text-sm font-semibold', !done && 'text-ink-soft')}>{title}</p>
        {note && <p className="text-xs text-ink-faint">{note}</p>}
      </div>
    </li>
  );
}

function ReturnCard({ order, ret }) {
  const qc = useQueryClient();
  const cancel = useMutation({
    mutationFn: () => orderApi.cancelReturn(order.id, ret.id),
    onSuccess: (data) => { qc.setQueryData(['orders', String(order.id)], data); qc.invalidateQueries({ queryKey: ['orders'] }); toast.success('Request cancelled'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const isReturn = ret.kind === 'return';
  const s = ret.status;
  const progress = [...OPEN_RETURNS, 'completed'];
  const reached = (k) => progress.indexOf(s) >= progress.indexOf(k);
  const steps = [
    ['requested', 'Request received', dateTime(ret.created_at)],
    ['pickup_scheduled', 'Pickup scheduled', ret.return_courier ? `${ret.return_courier} · AWB ${ret.return_awb}` : 'We’ll book a courier to collect it'],
    ['picked_up', 'Picked up', ret.picked_up_at && dateTime(ret.picked_up_at)],
    ['received', 'Received by us', ret.received_at && dateTime(ret.received_at)],
    ['completed', isReturn ? `Refund of ${price(ret.refund_amount)} sent` : 'Replacement shipped',
      ret.completed_at && `${dateTime(ret.completed_at)}${ret.refund_reference ? ` · UPI ref ${ret.refund_reference}` : ''}${ret.repl_courier ? ` · ${ret.repl_courier}, AWB ${ret.repl_awb}` : ''}`],
  ];

  return (
    <div className="rounded-2xl border border-line p-4 sm:p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="font-semibold">{isReturn ? 'Return' : 'Exchange'} · {ret.items.map((x) => `${x.product_name}${x.quantity > 1 ? ` ×${x.quantity}` : ''}`).join(', ')}</p>
        <span className={cn('badge', s === 'completed' ? 'bg-success/10 text-success' : ['rejected', 'cancelled'].includes(s) ? 'bg-danger/10 text-danger' : 'bg-warning/10 text-warning')}>{RETURN_LABELS[s]}</span>
      </div>
      <p className="mt-1 text-xs text-ink-soft">{ret.reason}{ret.comment && ` — “${ret.comment}”`}</p>

      {['rejected', 'cancelled'].includes(s) ? (
        <p className="mt-3 text-sm text-ink-soft">{s === 'rejected' ? `We couldn’t accept this request${ret.admin_note ? `: ${ret.admin_note}` : '.'}` : 'You cancelled this request.'}</p>
      ) : (
        <ol className="mt-4">
          {steps.map(([k, title, note], n) => (
            <Step key={k} done={reached(k)} current={!reached(k) && reached(steps[n - 1][0])} title={title} note={note} last={n === steps.length - 1} />
          ))}
        </ol>
      )}

      <div className="mt-3 flex flex-wrap gap-2">
        {ret.return_tracking_url && OPEN_RETURNS.includes(s) && <a href={ret.return_tracking_url} target="_blank" rel="noopener noreferrer" className="btn-outline btn-sm">Track pickup <ArrowUpRight size={14} /></a>}
        {ret.repl_tracking_url && <a href={ret.repl_tracking_url} target="_blank" rel="noopener noreferrer" className="btn-primary btn-sm">Track replacement <ArrowUpRight size={14} /></a>}
        {CANCELLABLE.includes(s) && (
          <button className="btn-ghost btn-sm text-danger" disabled={cancel.isPending} onClick={() => window.confirm('Cancel this request?') && cancel.mutate()}>
            {cancel.isPending ? 'Cancelling…' : 'Cancel request'}
          </button>
        )}
      </div>
    </div>
  );
}

/** Amazon-style returns on a delivered order: a 5-day window, then pickup by courier and refund or replacement */
export default function Returns({ order }) {
  const [open, setOpen] = useState(false);
  const left = available(order);
  const until = order.return_until && new Date(order.return_until);
  const windowOpen = until && until > new Date();
  const anyLeft = Object.values(left).some((n) => n > 0);
  if (order.status !== 'delivered' && !order.returns?.length) return null;

  return (
    <div className="card p-5 text-sm sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="flex items-center gap-2 font-semibold"><RotateCcw size={16} /> Return or exchange</h3>
          <p className="mt-0.5 text-xs text-ink-soft">
            {windowOpen ? `Eligible until ${date(order.return_until, { day: 'numeric', month: 'short' })} (${RETURN_DAYS} days after delivery)`
              : until ? `Return window closed on ${date(order.return_until, { day: 'numeric', month: 'short' })}` : null}
          </p>
        </div>
        {windowOpen && anyLeft && !open && <button className="btn-outline btn-sm" onClick={() => setOpen(true)}>Return / Exchange</button>}
      </div>
      {open && <ReturnForm order={order} left={left} onDone={() => setOpen(false)} />}
      {order.returns?.length > 0 && (
        <div className="mt-5 space-y-3">{[...order.returns].reverse().map((r) => <ReturnCard key={r.id} order={order} ret={r} />)}</div>
      )}
    </div>
  );
}
