import { AnimatePresence, motion } from 'framer-motion';
import { ShoppingBag, Trash2, Truck } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { useUI } from '../../context/UIContext';
import { price, sized } from '../../lib/format';
import { Empty, Qty } from '../ui/bits';
import { Drawer } from '../ui/Drawer';

export function FreeShippingMeter({ subtotal, threshold }) {
  const left = Math.max(0, threshold - subtotal);
  const pct = Math.min(100, (subtotal / threshold) * 100);
  return (
    <div className="rounded-2xl bg-brand-soft p-4">
      <p className="flex items-center gap-2 text-sm font-medium text-ink">
        <Truck size={16} className="text-brand" />
        {left > 0 ? <>Add <b>{price(left)}</b> more for <b>free delivery</b></> : <>🎉 You’ve unlocked <b>free delivery</b></>}
      </p>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-surface">
        <motion.div className="h-full rounded-full bg-brand" initial={{ width: 0 }} animate={{ width: `${pct}%` }}
          transition={{ type: 'spring', stiffness: 80, damping: 18 }} />
      </div>
    </div>
  );
}

export function CartLine({ item, compact }) {
  const { update, remove, busy } = useCart();
  return (
    <motion.li layout initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40, height: 0, marginTop: 0, paddingTop: 0, paddingBottom: 0 }}
      transition={{ duration: 0.3 }} className="flex gap-4 py-4">
      <Link to={`/product/${item.product_slug}`} className="shrink-0">
        <img src={sized(item.product_image, 200)} alt="" className={compact ? 'h-20 w-16 rounded-xl object-cover' : 'h-28 w-24 rounded-2xl object-cover'} />
      </Link>
      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex justify-between gap-2">
          <div className="min-w-0">
            {item.product_brand && <p className="text-[11px] font-semibold uppercase tracking-wider text-ink-faint">{item.product_brand}</p>}
            <Link to={`/product/${item.product_slug}`} className="line-clamp-2 text-sm font-medium hover:text-brand">{item.product_name}</Link>
            {item.product_name_mr && <p lang="mr" className="line-clamp-1 text-xs text-ink-soft">{item.product_name_mr}</p>}
          </div>
          <button onClick={() => remove(item)} className="btn-icon -mr-2 -mt-1 h-8 w-8 shrink-0 hover:text-danger" aria-label="Remove item"><Trash2 size={15} /></button>
        </div>
        <div className="mt-auto flex items-end justify-between pt-2">
          <Qty size="sm" value={item.quantity} max={Math.min(20, item.stock_quantity)} disabled={busy} onChange={(q) => update(item, q)} />
          <div className="text-right">
            <p className="text-sm font-bold">{price(item.product_price * item.quantity)}</p>
            {item.compare_at_price > item.product_price && (
              <p className="text-xs text-ink-faint line-through">{price(item.compare_at_price * item.quantity)}</p>
            )}
          </div>
        </div>
      </div>
    </motion.li>
  );
}

export default function CartDrawer() {
  const { cartOpen, setCartOpen } = useUI();
  const { cart } = useCart();
  const navigate = useNavigate();
  const close = () => setCartOpen(false);

  return (
    <Drawer open={cartOpen} onClose={close} title={`Your bag (${cart.total_items})`}
      footer={cart.items.length > 0 && (
        <div className="space-y-3">
          <div className="flex justify-between text-sm"><span className="text-ink-soft">Subtotal</span><span className="font-semibold">{price(cart.subtotal)}</span></div>
          <div className="flex justify-between text-sm"><span className="text-ink-soft">Delivery</span><span className="font-semibold">{cart.shipping_amount ? price(cart.shipping_amount) : 'Free'}</span></div>
          <div className="flex justify-between border-t border-line pt-3 font-display text-lg font-bold"><span>Total</span><span>{price(cart.total_amount)}</span></div>
          <p className="text-xs text-ink-faint">Inclusive of all taxes</p>
          <div className="grid grid-cols-2 gap-2 pt-1">
            <button className="btn-outline" onClick={() => { close(); navigate('/cart'); }}>View bag</button>
            <button className="btn-primary" onClick={() => { close(); navigate('/checkout'); }}>Checkout</button>
          </div>
        </div>
      )}>
      {cart.items.length === 0 ? (
        <Empty icon={ShoppingBag} title="Your bag is empty" text="Looks like you haven’t added anything yet."
          action={<button className="btn-primary" onClick={() => { close(); navigate('/shop'); }}>Start shopping</button>} />
      ) : (
        <div className="p-5">
          <FreeShippingMeter subtotal={cart.subtotal} threshold={cart.free_shipping_threshold} />
          <ul className="divide-y divide-line">
            <AnimatePresence initial={false}>
              {cart.items.map((item) => <CartLine key={item.id} item={item} compact />)}
            </AnimatePresence>
          </ul>
        </div>
      )}
    </Drawer>
  );
}
