import { useEffect } from 'react';
import { useLocation, useOutlet } from 'react-router-dom';
import { PageTransition } from '../ui/motion';
import CartDrawer from './CartDrawer';
import Footer from './Footer';
import Header from './Header';
import SearchPalette from './SearchPalette';

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
        <PageTransition key={location.pathname}>{outlet}</PageTransition>
      </main>
      <Footer />
      <CartDrawer />
      <SearchPalette />
    </div>
  );
}
