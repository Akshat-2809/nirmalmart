// index.html starts a few public API requests before the app's JavaScript has loaded.
// takePrefetched() hands such a response to React Query once (later refetches go to the network).
export function takePrefetched(url, fallback) {
  const store = typeof window !== 'undefined' ? window.__nmPrefetch : null;
  const p = store?.[url];
  if (!p) return fallback();
  delete store[url];
  return p.catch(() => fallback());   // if the early request failed, just ask again normally
}
