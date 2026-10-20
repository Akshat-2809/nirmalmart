import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
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

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false } },
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
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
    </QueryClientProvider>
  </React.StrictMode>,
);
