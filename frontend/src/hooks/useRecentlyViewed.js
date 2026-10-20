import { useCallback, useState } from 'react';
import { store } from '../lib/storage';

const KEY = 'nm-recent';

export function useRecentlyViewed() {
  const [items, setItems] = useState(() => store.get(KEY, []));
  const push = useCallback((p) => {
    const slim = { id: p.id, name: p.name, slug: p.slug, brand: p.brand, price: p.price,
      compare_at_price: p.compare_at_price, images: p.images?.slice(0, 1), rating_avg: p.rating_avg,
      rating_count: p.rating_count, stock_quantity: p.stock_quantity };
    const next = [slim, ...store.get(KEY, []).filter((x) => x.id !== p.id)].slice(0, 12);
    store.set(KEY, next);
    setItems(next);
  }, []);
  return { items, push };
}
