import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { cartApi, catalogApi } from '../api';
import { errorMessage } from '../api/client';
import { store } from '../lib/storage';
import { productImage } from '../lib/format';
import { useAuth } from './AuthContext';

const CartContext = createContext(null);
const GUEST_KEY = 'nm-guest-cart';
// Mirrors backend pricing rules (GST-inclusive prices) so guest totals match checkout
const FREE_SHIPPING = 499;
const SHIPPING_FEE = 49;
const GST = 0.18;

const summarise = (items) => {
  const subtotal = items.reduce((s, i) => s + i.product_price * i.quantity, 0);
  const shipping = subtotal === 0 || subtotal >= FREE_SHIPPING ? 0 : SHIPPING_FEE;
  return {
    items,
    total_items: items.reduce((s, i) => s + i.quantity, 0),
    subtotal,
    tax_amount: +(subtotal - subtotal / (1 + GST)).toFixed(2),
    shipping_amount: shipping,
    total_amount: subtotal + shipping,
    free_shipping_threshold: FREE_SHIPPING,
  };
};

const EMPTY = summarise([]);

export function CartProvider({ children }) {
  const { user, loading: authLoading } = useAuth();
  const [cart, setCart] = useState(EMPTY);
  const [busy, setBusy] = useState(false);
  const [ready, setReady] = useState(false);
  const mergedFor = useRef(null);

  const setGuest = (items) => {
    store.set(GUEST_KEY, items);
    setCart(summarise(items));
  };

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      mergedFor.current = null;
      const saved = store.get(GUEST_KEY, []);
      setCart(summarise(saved));
      setReady(true);
      if (saved.length) {   // refresh price / photo / stock so the guest bag never shows stale data
        catalogApi.byIds(saved.map((i) => i.product_id)).then(({ items: fresh }) => {
          const byId = new Map(fresh.map((p) => [p.id, p]));
          const next = saved.filter((i) => byId.has(i.product_id)).map((i) => {
            const p = byId.get(i.product_id);
            const quantity = Math.max(1, Math.min(i.quantity, p.stock_quantity || i.quantity));
            return { ...i, product_name: p.name, product_name_mr: p.name_mr, product_slug: p.slug, product_price: p.price,
              compare_at_price: p.compare_at_price, product_image: productImage(p), stock_quantity: p.stock_quantity,
              quantity, subtotal: p.price * quantity };
          });
          store.set(GUEST_KEY, next); setCart(summarise(next));
        }).catch(() => {});
      }
      return;
    }
    setReady(false);
    const guest = store.get(GUEST_KEY, []);
    const load = guest.length && mergedFor.current !== user.id
      ? cartApi.merge(guest.map((i) => ({ product_id: i.product_id, quantity: i.quantity })))
      : cartApi.get();
    mergedFor.current = user.id;
    load.then((c) => { setCart(c); store.remove(GUEST_KEY); }).catch(() => {}).finally(() => setReady(true));
  }, [user, authLoading]);

  const run = async (fn) => {
    setBusy(true);
    try {
      setCart(await fn());
      return true;
    } catch (e) {
      toast.error(errorMessage(e));
      return false;
    } finally {
      setBusy(false);
    }
  };

  const add = useCallback(async (product, quantity = 1) => {
    if (user) return run(() => cartApi.add(product.id, quantity));
    const items = [...cart.items];
    const existing = items.find((i) => i.product_id === product.id);
    const next = (existing?.quantity || 0) + quantity;
    if (next > product.stock_quantity) {
      toast.error(product.stock_quantity ? `Only ${product.stock_quantity} left in stock` : 'Out of stock');
      return false;
    }
    if (existing) existing.quantity = next;
    else items.unshift({
      id: `g-${product.id}`, product_id: product.id, product_name: product.name, product_name_mr: product.name_mr, product_slug: product.slug,
      product_brand: product.brand, product_price: product.price, compare_at_price: product.compare_at_price,
      product_image: productImage(product), stock_quantity: product.stock_quantity, quantity,
    });
    setGuest(items.map((i) => ({ ...i, subtotal: i.product_price * i.quantity })));
    return true;
  }, [user, cart.items]);

  const update = useCallback(async (item, quantity) => {
    if (user) return run(() => cartApi.update(item.id, quantity));
    if (quantity > item.stock_quantity) {
      toast.error(`Only ${item.stock_quantity} left in stock`);
      return false;
    }
    setGuest(cart.items
      .map((i) => (i.id === item.id ? { ...i, quantity, subtotal: i.product_price * quantity } : i))
      .filter((i) => i.quantity > 0));
    return true;
  }, [user, cart.items]);

  const remove = useCallback(async (item) => {
    if (user) return run(() => cartApi.remove(item.id));
    setGuest(cart.items.filter((i) => i.id !== item.id));
    return true;
  }, [user, cart.items]);

  const refresh = useCallback(() => (user ? cartApi.get().then(setCart) : null), [user]);

  const value = useMemo(() => ({ cart, busy, ready, add, update, remove, refresh, reset: () => setCart(EMPTY) }),
    [cart, busy, ready, add, update, remove, refresh]);
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export const useCart = () => useContext(CartContext);
