import { QueryClient } from '@tanstack/react-query';
import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister';
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client';
import { MotionConfig } from 'framer-motion';
import React from 'react';
import ReactDOM from 'react-dom/client';
import { Toaster } from 'react-hot-toast';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { UIProvider } from './context/UIContext';
import { WishlistProvider } from './context/WishlistContext';
import './index.css';
import { watchForNewVersion } from './lib/version';

watchForNewVersion();

// Any image that fails to load (deleted/renamed file, flaky network) shows a soft placeholder
// instead of the browser's broken-image icon.
const IMG_FALLBACK = `data:image/svg+xml;utf8,${encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120"><rect width="120" height="120" fill="#efefec"/>'
  + '<path d="M38 80l16-20 12 14 8-10 12 16z" fill="#c9c9c2"/><circle cx="74" cy="46" r="7" fill="#c9c9c2"/></svg>',
)}`;
window.addEventListener('error', (e) => {
  const el = e.target;
  if (el?.tagName === 'IMG' && !el.dataset.fallback) {
    el.dataset.fallback = '1';
    el.removeAttribute('srcset');
    el.src = IMG_FALLBACK;
  }
}, true);

// Retry while the backend wakes up or a request times out (no response / 5xx); never retry 4xx.
const retry = (count, err) => count < 4 && (!err?.response || err.response.status >= 500);
const retryDelay = (n) => Math.min(1500 * 2 ** n, 8000);

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, gcTime: 24 * 60 * 60 * 1000, retry, retryDelay, refetchOnWindowFocus: false } },
});

// Public catalogue data (products, categories) is remembered in the browser, so returning visitors
// see the store instantly; fresh data replaces it in the background. Personal data is never stored.
const PUBLIC_KEYS = new Set(['products', 'categories', 'product', 'related', 'facets']);
let storage;
try { storage = window.localStorage; } catch { storage = undefined; }
const persister = createSyncStoragePersister({ storage, key: 'nm-catalog-cache', throttleTime: 2000 });
const persistOptions = {
  persister,
  maxAge: 24 * 60 * 60 * 1000,
  buster: 'v2',
  dehydrateOptions: { shouldDehydrateQuery: (q) => q.state.status === 'success' && PUBLIC_KEYS.has(q.queryKey[0]) },
};

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <PersistQueryClientProvider client={queryClient} persistOptions={persistOptions}>
      <BrowserRouter>
        <MotionConfig reducedMotion="user">
          <AuthProvider>
            <UIProvider>
              <CartProvider>
                <WishlistProvider>
                  <App />
                  <Toaster position="bottom-center" toastOptions={{
                    className: '!rounded-full !bg-ink !px-4 !py-2.5 !text-sm !font-medium !text-bg !shadow-lift',
                    success: { iconTheme: { primary: 'rgb(var(--success))', secondary: '#fff' } },
                  }} />
                </WishlistProvider>
              </CartProvider>
            </UIProvider>
          </AuthProvider>
        </MotionConfig>
      </BrowserRouter>
    </PersistQueryClientProvider>
  </React.StrictMode>,
);
