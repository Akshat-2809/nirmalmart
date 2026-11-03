import { useMutation, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Check, MessageCircle, X } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { orderApi } from '../../api';
import { errorMessage } from '../../api/client';
import { cn } from '../../lib/cn';
import { PAYMENT } from '../../lib/contact';
import { dateTime, price } from '../../lib/format';

// Like Amazon: customers can cancel until the courier has picked the parcel up
export const CANCELLABLE = ['pending', 'confirmed', 'processing'];
const REASONS = ['Ordered by mistake', 'Changed my mind', 'Found a better price elsewhere', 'Delivery is taking too long', 'Need to change the address or items', 'Other'];

const waLink = (text) => `https://wa.me/${PAYMENT.wa}?text=${encodeURIComponent(text)}`;

/** "Cancel order" button that opens a short reason picker before cancelling */
export function CancelOrder({ order }) {
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState('');
  const cancel = useMutation({
    mutationFn: () => orderApi.cancel(order.id, reason || undefined),
    onSuccess: (data) => {
      qc.setQueryData(['orders', String(order.id)], data);
      qc.invalidateQueries({ queryKey: ['orders'] });
      toast.success('Order cancelled');
    },
    onError: (e) => toast.error(errorMessage(e)),
  });
  if (!CANCELLABLE.includes(order.status)) return null;
  const paid = order.payment_status === 'paid';

  return (
    <div className="card p-5 text-sm">
      {!open ? (
        <button className="btn-outline w-full text-danger hover:border-danger" onClick={() => setOpen(true)}>Cancel order</button>
      ) : (
          <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
            <h3 className="font-semibold">Why are you cancelling?</h3>
            <div className="space-y-2">
              {REASONS.map((r) => (
                <label key={r} className={cn('flex cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 transition', reason === r ? 'border-brand bg-brand-soft/40' : 'border-line hover:border-ink/30')}>
                  <input type="radio" name="cancel-reason" value={r} checked={reason === r} onChange={() => setReason(r)} className="accent-brand" />
                  {r}
                </label>
              ))}
            </div>
            {order.awb_code && <p className="rounded-xl bg-muted/60 p-3 text-xs text-ink-soft">Your parcel is packed. Cancelling now also cancels the courier pickup.</p>}
            <p className="text-xs text-ink-soft">
              {paid ? <>Your <b className="text-ink">{price(order.total_amount)}</b> will be refunded to the UPI account you paid from.</>
                : 'No payment has been confirmed for this order, so nothing will be charged.'}
            </p>
            <div className="flex gap-2">
              <button className="btn-outline flex-1" onClick={() => setOpen(false)} disabled={cancel.isPending}>Keep order</button>
              <button className="btn flex-1 bg-danger text-white hover:brightness-110" onClick={() => cancel.mutate()} disabled={cancel.isPending}>
                {cancel.isPending ? 'Cancelling…' : 'Cancel order'}
              </button>
            </div>
          </motion.div>
      )}
    </div>
  );
}

function Step({ done, title, note, last }) {
  return (
    <li className="relative flex gap-3 pb-5 last:pb-0">
      {!last && <span className={cn('absolute left-[13px] top-7 h-[calc(100%-1.5rem)] w-0.5', done ? 'bg-success' : 'bg-muted')} />}
      <span className={cn('grid h-7 w-7 shrink-0 place-items-center rounded-full', done ? 'bg-success text-white' : 'border-2 border-line bg-surface text-ink-faint')}>
        {done ? <Check size={14} strokeWidth={3} /> : <span className="h-1.5 w-1.5 rounded-full bg-current" />}
      </span>
      <div className="pt-0.5">
        <p className={cn('font-semibold', !done && 'text-ink-soft')}>{title}</p>
        {note && <p className="text-xs text-ink-faint">{note}</p>}
      </div>
    </li>
  );
}

/** Shown on a cancelled order: when and why, plus Amazon-style refund progress */
export function CancellationStatus({ order }) {
  const cancelledAt = order.cancelled_at || order.updated_at;
  const ps = order.payment_status;
  const refunding = ps === 'refund_pending' || ps === 'refunded';
  const amount = price(order.total_amount);

  return (
    <div className="space-y-4 text-sm">
      <div className="flex items-start gap-3 rounded-2xl bg-danger/10 p-4 text-danger">
        <X size={18} className="mt-0.5 shrink-0" />
        <div>
          <p className="font-semibold">Order cancelled on {dateTime(cancelledAt)}</p>
          {order.cancel_reason && <p className="text-danger/80">{order.cancel_reason}</p>}
        </div>
      </div>

      {refunding ? (
        <div className="rounded-2xl border border-line p-4 sm:p-5">
          <div className="mb-4 flex flex-wrap items-baseline justify-between gap-2">
            <h3 className="font-display text-lg font-bold">Refund of {amount}</h3>
            <span className={cn('badge', ps === 'refunded' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning')}>{ps === 'refunded' ? 'Refunded' : 'In progress'}</span>
          </div>
          <ol>
            <Step done title="Order cancelled" note={dateTime(cancelledAt)} />
            <Step done title="Refund initiated" note={`${amount} to the UPI account you paid from`} />
            <Step last done={ps === 'refunded'} title={ps === 'refunded' ? 'Refund credited' : 'Refund to be credited'}
              note={ps === 'refunded'
                ? `${dateTime(order.refunded_at)}${order.refund_reference ? ` · UPI ref ${order.refund_reference}` : ''}`
                : 'Usually within a few working days'} />
          </ol>
          {ps !== 'refunded' && (
            <a href={waLink(`Hello Nirmal Mart, I'd like an update on the refund for my cancelled order ${order.order_number} (${amount}).`)}
              target="_blank" rel="noopener noreferrer" className="mt-4 inline-flex items-center gap-1.5 text-xs font-semibold text-brand hover:underline">
              <MessageCircle size={14} /> Ask about this refund on WhatsApp
            </a>
          )}
        </div>
      ) : (
        <div className="rounded-2xl bg-muted/60 p-4 text-ink-soft">
          <p>No payment was taken for this order, so there’s nothing to refund.</p>
          <a href={waLink(`Hello Nirmal Mart, I had paid for order ${order.order_number} (${amount}) before it was cancelled. Please refund me. Payment screenshot attached.`)}
            target="_blank" rel="noopener noreferrer" className="mt-2 inline-flex items-center gap-1.5 text-xs font-semibold text-brand hover:underline">
            <MessageCircle size={14} /> Already paid by UPI? Tell us on WhatsApp
          </a>
        </div>
      )}
    </div>
  );
}
