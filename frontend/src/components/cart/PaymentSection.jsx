import { motion } from 'framer-motion';
import { CreditCard, Info, Landmark, Smartphone, Wallet } from 'lucide-react';

/**
 * Payment step of checkout. The payment gateway (Razorpay) and Cash on Delivery
 * are pending a decision from the client, so for now orders are placed with
 * payment status "pending". When the gateway is enabled, this component is the
 * single place that changes: open Razorpay Checkout here and resolve `onPay`
 * only after the backend verifies the payment signature.
 */
export default function PaymentSection() {
  return (
    <div className="space-y-4">
      <motion.div layout className="rounded-2xl border-2 border-brand bg-brand-soft/50 p-4">
        <div className="flex items-center gap-3">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-brand text-brand-ink"><Wallet size={18} /></span>
          <div className="flex-1">
            <p className="font-semibold">Pay online</p>
            <p className="text-xs text-ink-soft">UPI, cards, net banking & wallets</p>
          </div>
          <span className="h-5 w-5 rounded-full border-[6px] border-brand bg-surface" />
        </div>
        <div className="mt-4 flex flex-wrap gap-2">
          {[[Smartphone, 'UPI'], [CreditCard, 'Cards'], [Landmark, 'Net banking'], [Wallet, 'Wallets']].map(([Icon, l]) => (
            <span key={l} className="inline-flex items-center gap-1.5 rounded-full bg-surface px-3 py-1.5 text-xs font-medium text-ink-soft"><Icon size={13} /> {l}</span>
          ))}
        </div>
      </motion.div>
      <p className="flex gap-2 rounded-2xl bg-warning/10 p-3 text-xs leading-relaxed text-ink-soft">
        <Info size={15} className="mt-0.5 shrink-0 text-warning" />
        Online payment is being activated. Your order will be placed with payment pending, and our team will confirm it with you.
      </p>
    </div>
  );
}
