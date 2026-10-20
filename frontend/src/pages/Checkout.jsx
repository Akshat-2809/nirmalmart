import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import { Check, ChevronRight, Lock, MapPin, Pencil, Plus } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { orderApi, userApi } from '../api';
import { errorMessage } from '../api/client';
import AddressForm from '../components/cart/AddressForm';
import PaymentSection from '../components/cart/PaymentSection';
import { Skeleton } from '../components/ui/bits';
import { useCart } from '../context/CartContext';
import { cn } from '../lib/cn';
import { deliveryDate, price, sized } from '../lib/format';
import { OrderSummary } from './Cart';

const STEPS = ['Address', 'Review', 'Payment'];

function StepHeader({ n, title, done, active, onEdit, summary }) {
  return (
    <div className="flex items-center gap-4">
      <motion.span animate={{ backgroundColor: done || active ? 'rgb(var(--ink))' : 'rgb(var(--muted))', color: done || active ? 'rgb(var(--bg))' : 'rgb(var(--ink-faint))' }}
        className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-sm font-bold">
        {done ? <Check size={16} /> : n}
      </motion.span>
      <div className="min-w-0 flex-1">
        <h2 className={cn('font-display text-lg font-bold', !active && !done && 'text-ink-faint')}>{title}</h2>
        {done && summary && <p className="truncate text-sm text-ink-soft">{summary}</p>}
      </div>
      {done && onEdit && <button onClick={onEdit} className="btn-ghost btn-sm"><Pencil size={14} /> Change</button>}
    </div>
  );
}

export default function Checkout() {
  const { cart, ready, reset } = useCart();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [step, setStep] = useState(0);
  const [addressId, setAddressId] = useState(null);
  const [adding, setAdding] = useState(false);
  const [notes, setNotes] = useState('');

  const { data: addresses, isPending } = useQuery({ queryKey: ['addresses'], queryFn: userApi.addresses });
  useEffect(() => {
    if (addresses && !addressId) {
      const def = addresses.find((a) => a.is_default) || addresses[0];
      if (def) setAddressId(def.id);
      else setAdding(true);
    }
  }, [addresses, addressId]);

  const addAddress = useMutation({
    mutationFn: userApi.addAddress,
    onSuccess: (a) => { qc.invalidateQueries({ queryKey: ['addresses'] }); setAddressId(a.id); setAdding(false); toast.success('Address saved'); },
    onError: (e) => toast.error(errorMessage(e)),
  });
  const placeOrder = useMutation({
    mutationFn: () => orderApi.create({ address_id: addressId, notes: notes || undefined }),
    onSuccess: (order) => {
      reset();
      qc.invalidateQueries({ queryKey: ['orders'] });
      qc.invalidateQueries({ queryKey: ['products'] });
      navigate(`/order/${order.id}/success`, { replace: true });
    },
    onError: (e) => toast.error(errorMessage(e, 'Could not place your order')),
  });

  if (!ready) return <div className="container py-10"><Skeleton className="h-96" /></div>;
  if (!cart.items.length && !placeOrder.isPending && !placeOrder.isSuccess) return <Navigate to="/cart" replace />;
  const selected = addresses?.find((a) => a.id === addressId);

  return (
    <div className="container py-10">
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <h1 className="font-display text-3xl font-extrabold sm:text-4xl">Checkout</h1>
        <ol className="flex items-center gap-2 text-sm">
          {STEPS.map((s, i) => (
            <li key={s} className="flex items-center gap-2">
              <span className={cn('font-medium transition', i <= step ? 'text-ink' : 'text-ink-faint')}>{s}</span>
              {i < STEPS.length - 1 && <ChevronRight size={14} className="text-ink-faint" />}
            </li>
          ))}
        </ol>
      </div>

      <div className="grid gap-8 lg:grid-cols-[1fr_380px]">
        <div className="space-y-4">
          {/* Step 1: address */}
          <section className="card p-5 sm:p-6">
            <StepHeader n={1} title="Delivery address" active={step === 0} done={step > 0} onEdit={() => setStep(0)}
              summary={selected && `${selected.full_name}, ${selected.address_line1}, ${selected.city} ${selected.postal_code}`} />
            <AnimatePresence initial={false}>
              {step === 0 && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
                  <div className="pt-6">
                    {isPending ? <Skeleton className="h-28" /> : (
                      <div className="grid gap-3 sm:grid-cols-2">
                        {addresses.map((a) => (
                          <motion.button layout key={a.id} onClick={() => { setAddressId(a.id); setAdding(false); }}
                            className={cn('relative rounded-2xl border-2 p-4 text-left transition', a.id === addressId && !adding ? 'border-brand bg-brand-soft/40' : 'border-line hover:border-ink/30')}>
                            <span className="badge mb-2 bg-muted text-ink-soft">{a.label}</span>
                            <p className="text-sm font-semibold">{a.full_name} · {a.phone}</p>
                            <p className="mt-1 text-sm text-ink-soft">{a.address_line1}{a.address_line2 && `, ${a.address_line2}`}, {a.city}, {a.state} – {a.postal_code}</p>
                            {a.id === addressId && !adding && (
                              <motion.span layoutId="addr-check" className="absolute right-3 top-3 grid h-6 w-6 place-items-center rounded-full bg-brand text-brand-ink"><Check size={14} /></motion.span>
                            )}
                          </motion.button>
                        ))}
                        {!adding && (
                          <button onClick={() => setAdding(true)} className="flex min-h-[120px] flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-line text-sm font-semibold text-ink-soft transition hover:border-brand hover:text-brand">
                            <Plus size={20} /> Add new address
                          </button>
                        )}
                      </div>
                    )}
                    <AnimatePresence>
                      {adding && (
                        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mt-5 rounded-2xl bg-muted/50 p-5">
                          <p className="mb-4 flex items-center gap-2 font-semibold"><MapPin size={16} /> New address</p>
                          <AddressForm onSubmit={(a) => addAddress.mutate(a)} submitting={addAddress.isPending} submitLabel="Save and use this address"
                            onCancel={addresses?.length ? () => setAdding(false) : undefined} initial={{ is_default: !addresses?.length }} />
                        </motion.div>
                      )}
                    </AnimatePresence>
                    {!adding && (
                      <button className="btn-dark mt-6" disabled={!addressId} onClick={() => setStep(1)}>Deliver here</button>
                    )}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </section>

          {/* Step 2: review */}
          <section className="card p-5 sm:p-6">
            <StepHeader n={2} title="Review items" active={step === 1} done={step > 1} onEdit={() => setStep(1)}
              summary={`${cart.total_items} items · arriving by ${deliveryDate(4)}`} />
            <AnimatePresence initial={false}>
              {step === 1 && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
                  <div className="pt-6">
                    <p className="mb-4 rounded-xl bg-success/10 px-4 py-2.5 text-sm text-success">Estimated delivery: <b>{deliveryDate(3)} – {deliveryDate(5)}</b></p>
                    <ul className="divide-y divide-line">
                      {cart.items.map((i) => (
                        <li key={i.id} className="flex items-center gap-4 py-3">
                          <img src={sized(i.product_image, 160)} alt="" className="h-16 w-14 rounded-xl object-cover" />
                          <div className="min-w-0 flex-1"><p className="line-clamp-1 text-sm font-medium">{i.product_name}</p><p className="text-xs text-ink-faint">Qty {i.quantity}</p></div>
                          <p className="text-sm font-semibold">{price(i.product_price * i.quantity)}</p>
                        </li>
                      ))}
                    </ul>
                    <textarea value={notes} onChange={(e) => setNotes(e.target.value)} maxLength={500} placeholder="Delivery instructions (optional)" className="input mt-4 h-20 py-3" />
                    <button className="btn-dark mt-5" onClick={() => setStep(2)}>Continue to payment</button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </section>

          {/* Step 3: payment */}
          <section className="card p-5 sm:p-6">
            <StepHeader n={3} title="Payment" active={step === 2} />
            <AnimatePresence initial={false}>
              {step === 2 && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
                  <div className="pt-6"><PaymentSection /></div>
                </motion.div>
              )}
            </AnimatePresence>
          </section>
        </div>

        <div className="lg:sticky lg:top-32 lg:self-start">
          <OrderSummary cart={cart}>
            <motion.button whileTap={{ scale: 0.98 }} disabled={step < 2 || placeOrder.isPending} onClick={() => placeOrder.mutate()}
              className="btn-primary btn-lg mt-6 w-full">
              {placeOrder.isPending ? <><span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-r-transparent" /> Placing order…</> : <><Lock size={16} /> Place order · {price(cart.total_amount)}</>}
            </motion.button>
            {step < 2 && <p className="mt-3 text-center text-xs text-ink-faint">Complete the steps to place your order</p>}
            <p className="mt-4 text-center text-xs text-ink-faint">By placing your order you agree to our <Link to="/" className="underline">terms</Link>.</p>
          </OrderSummary>
        </div>
      </div>
    </div>
  );
}
