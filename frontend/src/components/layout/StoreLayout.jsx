import { Suspense, useEffect } from 'react';
import { useLocation, useOutlet } from 'react-router-dom';
import { PageTransition } from '../ui/motion';
import CartDrawer from './CartDrawer';
import Footer from './Footer';
import Header from './Header';
import SearchPalette from './SearchPalette';

function PageSkeleton() {
  return (
    <div className="container grid gap-6 py-8 lg:grid-cols-2" aria-busy="true">
      <div className="skeleton aspect-square rounded-3xl" />
      <div className="space-y-4"><div className="skeleton h-8 w-3/4" /><div className="skeleton h-6 w-1/3" /><div className="skeleton h-32" /></div>
    </div>
  );
}

export default function StoreLayout() {
  const location = useLocation();
  const outlet = useOutlet();

  // Scroll to top on page change, but not when only filters (query string) change
  useEffect(() => { window.scrollTo({ top: 0, behavior: 'instant' }); }, [location.pathname]);

  return (
    <div className="flex min-h-screen flex-col">
      <Header />
      <main className="flex-1">
        {/* Enter-only transition: keeping the old page mounted for an exit animation would
            let its redirects (e.g. auth guards) fire again against the new URL */}
        <Suspense fallback={<PageSkeleton />}>
          <PageTransition key={location.pathname}>{outlet}</PageTransition>
        </Suspense>
      </main>
      <Footer />
      <CartDrawer />
      <SearchPalette />
    </div>
  );
}
