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
