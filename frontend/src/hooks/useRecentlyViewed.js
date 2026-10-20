import { useQuery } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { catalogApi } from '../api';
import { store } from '../lib/storage';

const KEY = 'nm-recent';

// Only product ids are remembered; names, prices and photos are always fetched fresh, so a renamed
// product or replaced photo never shows stale (or broken) data.
const readIds = () => store.get(KEY, []).map((x) => (typeof x === 'object' ? x?.id : x)).filter(Number.isInteger);

export function useRecentlyViewed() {
  const [ids, setIds] = useState(readIds);
  const push = useCallback((p) => {
    const next = [p.id, ...readIds().filter((id) => id !== p.id)].slice(0, 12);
    store.set(KEY, next);
    setIds(next);
  }, []);
  const { data } = useQuery({
    queryKey: ['products', { ids }],
    queryFn: () => catalogApi.byIds(ids),
    enabled: ids.length > 0,
    staleTime: 60_000,
  });
  const byId = new Map((data?.items || []).map((p) => [p.id, p]));
  const items = ids.map((id) => byId.get(id)).filter(Boolean); // keeps viewing order, drops removed products
  return { items, push };
}
