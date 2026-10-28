import { motion } from 'framer-motion';
import { Info, MessageCircle, QrCode } from 'lucide-react';

/**
 * Payment step of checkout. Customers pay by scanning the store's UPI QR after the
 * order is placed (see components/order/UpiPayment), then send proof on WhatsApp;
 * the admin checks it and marks the order paid. No payment gateway is involved.
 */
export default function PaymentSection() {
  return (
    <div className="space-y-4">
      <motion.div layout className="rounded-2xl border-2 border-brand bg-brand-soft/50 p-4">
        <div className="flex items-center gap-3">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-brand text-brand-ink"><QrCode size={18} /></span>
          <div className="flex-1">
            <p className="font-semibold">Pay by UPI</p>
            <p className="text-xs text-ink-soft">Google Pay, PhonePe, Paytm, BHIM or any UPI app</p>
          </div>
          <span className="h-5 w-5 rounded-full border-[6px] border-brand bg-surface" />
        </div>
      </motion.div>
      <p className="flex gap-2 rounded-2xl bg-muted/60 p-3 text-xs leading-relaxed text-ink-soft">
        <Info size={15} className="mt-0.5 shrink-0 text-brand" />
        <span>After you place the order you’ll see our UPI QR code and the exact amount. Pay, then tap
          <MessageCircle size={12} className="mx-1 inline align-[-2px]" /><b>Send payment proof on WhatsApp</b>. We confirm your order once the payment is checked.</span>
      </p>
    </div>
  );
}
