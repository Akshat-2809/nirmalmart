import { Copy, Download, MessageCircle } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { PAYMENT } from '../../lib/contact';
import { price, priceExact } from '../../lib/format';

/** Whether an order still needs the customer to pay by UPI QR */
export const awaitingUpi = (o) => !!o && o.payment_status === 'pending' && o.status !== 'cancelled';

const copy = async (text, label) => {
  try { await navigator.clipboard.writeText(text); toast.success(`${label} copied`); }
  catch { toast.error('Could not copy'); }
};

/**
 * Pay by scanning the store's UPI QR, then send proof on WhatsApp with the order details filled in.
 * WhatsApp links can't carry an image, so the customer attaches their payment screenshot in the chat.
 * The admin checks the payment and marks the order paid from the admin panel.
 */
export default function UpiPayment({ order }) {
  const [utr, setUtr] = useState('');
  const amount = Number(order.total_amount) % 1 ? priceExact(order.total_amount) : price(order.total_amount);
  const name = order.shipping_address?.full_name;
  const message = [
    'Hello Nirmal Mart, I have paid for my order.',
    `Order ID: ${order.order_number}`,
    `Amount: ${amount}`,
    name && `Name: ${name}`,
    utr.trim() && `UPI reference (UTR): ${utr.trim()}`,
    'Payment screenshot attached.',
  ].filter(Boolean).join('\n');
  const waLink = `https://wa.me/${PAYMENT.wa}?text=${encodeURIComponent(message)}`;

  return (
    <div className="card p-5 text-left sm:p-6">
      <p className="text-xs font-semibold uppercase tracking-wider text-warning">Payment pending</p>
      <h3 className="mt-1 font-display text-xl font-bold">Pay {amount} by UPI</h3>
      <p className="mt-1 text-sm text-ink-soft">Scan with Google Pay, PhonePe, Paytm, BHIM or any UPI app.</p>

      <div className="mt-5 grid items-start gap-5 sm:grid-cols-[220px_1fr]">
        <div className="mx-auto w-full max-w-[220px]">
          <img src={PAYMENT.qr} alt={`UPI QR code for ${PAYMENT.payee}`} width="720" height="1030" className="w-full rounded-2xl border border-line" />
          <a href={PAYMENT.qr} download="NirmalMart-UPI-QR.jpg" className="btn-outline btn-sm mt-3 w-full"><Download size={14} /> Save QR</a>
        </div>

        <div className="space-y-4 text-sm">
          <dl className="space-y-2 rounded-2xl bg-muted/60 p-4">
            <div className="flex items-center justify-between gap-2"><dt className="text-ink-soft">Amount</dt><dd className="font-display text-lg font-bold">{amount}</dd></div>
            <div className="flex items-center justify-between gap-2">
              <dt className="text-ink-soft">Order ID</dt>
              <dd className="flex items-center gap-1.5 font-semibold">{order.order_number}
                <button onClick={() => copy(order.order_number, 'Order ID')} aria-label="Copy order ID" className="text-ink-faint hover:text-ink"><Copy size={14} /></button></dd>
            </div>
            <div className="flex items-center justify-between gap-2">
              <dt className="shrink-0 text-ink-soft">UPI ID</dt>
              <dd className="flex min-w-0 items-center gap-1.5 font-medium"><span className="truncate">{PAYMENT.upiId}</span>
                <button onClick={() => copy(PAYMENT.upiId, 'UPI ID')} aria-label="Copy UPI ID" className="shrink-0 text-ink-faint hover:text-ink"><Copy size={14} /></button></dd>
            </div>
          </dl>

          <ol className="list-decimal space-y-1.5 pl-5 text-ink-soft">
            <li>Pay exactly <b className="text-ink">{amount}</b>. On your phone, tap <b>Save QR</b> and open it from the gallery in your UPI app.</li>
            <li>Take a screenshot of the successful payment.</li>
            <li>Tap the button below and attach the screenshot in WhatsApp.</li>
          </ol>

          <input value={utr} onChange={(e) => setUtr(e.target.value)} maxLength={40} inputMode="numeric"
            placeholder="UPI reference / UTR no. (optional)" className="input" />

          <a href={waLink} target="_blank" rel="noopener noreferrer"
            className="btn btn-lg w-full bg-[#128C4B] text-white hover:brightness-110">
            <MessageCircle size={18} /> Send payment proof on WhatsApp
          </a>
          <p className="text-xs text-ink-faint">Sends to {PAYMENT.waDisplay}. We’ll confirm your order once the payment is checked.</p>
        </div>
      </div>
    </div>
  );
}
