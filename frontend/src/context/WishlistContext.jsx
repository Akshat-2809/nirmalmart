import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import { wishlistApi } from '../api';
import { store } from '../lib/storage';
import { useAuth } from './AuthContext';

const WishlistContext = createContext(null);
const KEY = 'nm-guest-wishlist';

export function WishlistProvider({ children }) {
  const { user, loading } = useAuth();
  const [items, setItems] = useState([]);

  useEffect(() => {
    if (loading) return;
    if (!user) return setItems(store.get(KEY, []));
    const guest = store.get(KEY, []);
    Promise.all(guest.map((p) => wishlistApi.add(p.id).catch(() => null)))
      .then(() => wishlistApi.get())
      .then((list) => { setItems(list); store.remove(KEY); })
      .catch(() => {});
  }, [user, loading]);

  const has = useCallback((id) => items.some((p) => p.id === id), [items]);

  const toggle = useCallback(async (product) => {
    const on = has(product.id);
    if (!user) {
      const next = on ? items.filter((p) => p.id !== product.id) : [product, ...items];
      store.set(KEY, next);
      setItems(next);
    } else {
      setItems((prev) => (on ? prev.filter((p) => p.id !== product.id) : [product, ...prev]));
      try {
        setItems(await (on ? wishlistApi.remove(product.id) : wishlistApi.add(product.id)));
      } catch {
        toast.error('Could not update wishlist');
      }
    }
    toast.success(on ? 'Removed from wishlist' : 'Saved to wishlist', { icon: on ? '🤍' : '❤️' });
  }, [user, items, has]);

  const value = useMemo(() => ({ items, has, toggle }), [items, has, toggle]);
  return <WishlistContext.Provider value={value}>{children}</WishlistContext.Provider>;
}

export const useWishlist = () => useContext(WishlistContext);
