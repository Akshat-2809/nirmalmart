import { useQuery } from '@tanstack/react-query';
import { AnimatePresence, motion, useMotionValueEvent, useScroll } from 'framer-motion';
import { Heart, LayoutDashboard, LogOut, Menu, Moon, Package, Search, ShoppingBag, Sun, User } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { Link, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { catalogApi } from '../../api';
import { useAuth } from '../../context/AuthContext';
import { useCart } from '../../context/CartContext';
import { useUI } from '../../context/UIContext';
import { useWishlist } from '../../context/WishlistContext';
import { cn } from '../../lib/cn';
import { Logo } from '../ui/bits';
import { Drawer } from '../ui/Drawer';

const MESSAGES = [
  'Free delivery on orders above ₹499',
  'Easy 7-day returns on most items',
  'New arrivals every week — shop the latest drops',
];

function AnnouncementBar() {
  const [i, setI] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setI((n) => (n + 1) % MESSAGES.length), 4000);
    return () => clearInterval(t);
  }, []);
  return (
    <div className="relative h-9 overflow-hidden bg-ink text-bg">
      <AnimatePresence mode="wait">
        <motion.p key={i} className="absolute inset-0 grid place-items-center text-xs font-medium tracking-wide"
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -20, opacity: 0 }} transition={{ duration: 0.4 }}>
          {MESSAGES[i]}
        </motion.p>
      </AnimatePresence>
    </div>
  );
}

function AccountMenu() {
  const { user, isAdmin, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    const close = (e) => !ref.current?.contains(e.target) && setOpen(false);
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  if (!user) {
    return <Link to="/login" className="btn-icon" aria-label="Sign in"><User size={20} /></Link>;
  }
  const initials = user.full_name.split(' ').map((s) => s[0]).slice(0, 2).join('').toUpperCase();
  const items = [
    { to: '/account', icon: User, label: 'My account' },
    { to: '/account/orders', icon: Package, label: 'Orders' },
    { to: '/wishlist', icon: Heart, label: 'Wishlist' },
    ...(isAdmin ? [{ to: '/admin', icon: LayoutDashboard, label: 'Admin dashboard' }] : []),
  ];
  return (
    <div className="relative" ref={ref}>
      <button onClick={() => setOpen((o) => !o)} aria-expanded={open} aria-label="Account menu"
        className="ml-1 grid h-9 w-9 place-items-center rounded-full bg-brand-soft text-xs font-bold text-brand transition hover:ring-4 hover:ring-brand/15">
        {initials}
      </button>
      <AnimatePresence>
        {open && (
          <motion.div initial={{ opacity: 0, y: 8, scale: 0.97 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 6, scale: 0.98 }}
            transition={{ duration: 0.18 }}
            className="absolute right-0 top-12 z-50 w-60 origin-top-right rounded-2xl border border-line bg-surface p-2 shadow-lift">
            <div className="px-3 py-2">
              <p className="truncate text-sm font-semibold">{user.full_name}</p>
              <p className="truncate text-xs text-ink-faint">{user.email}</p>
            </div>
            <div className="my-1 h-px bg-line" />
            {items.map(({ to, icon: Icon, label }) => (
              <Link key={to} to={to} onClick={() => setOpen(false)}
                className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-ink-soft transition hover:bg-muted hover:text-ink">
                <Icon size={16} /> {label}
              </Link>
            ))}
            <button onClick={() => { logout(); setOpen(false); navigate('/'); }}
              className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-danger transition hover:bg-danger/10">
              <LogOut size={16} /> Sign out
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function Header() {
  const { data: categories = [] } = useQuery({ queryKey: ['categories'], queryFn: catalogApi.categories, staleTime: 300_000 });
  const { cart } = useCart();
  const { items: wish } = useWishlist();
  const { setCartOpen, setSearchOpen, theme, toggleTheme, cartIconRef, cartPulse } = useUI();
  const { pathname, search } = useLocation();
  const [hidden, setHidden] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, 'change', (y) => {
    const prev = scrollY.getPrevious() ?? 0;
    setHidden(y > prev && y > 220);
    setScrolled(y > 10);
  });
  useEffect(() => setMobileOpen(false), [pathname, search]);

  const activeCat = new URLSearchParams(search).get('category');

  return (
    <>
      <AnnouncementBar />
      <motion.header
        animate={{ y: hidden ? '-100%' : 0 }} transition={{ duration: 0.3, ease: 'easeOut' }}
        className={cn('sticky top-0 z-40 border-b transition-colors duration-300',
          scrolled ? 'border-line bg-bg/80 backdrop-blur-xl' : 'border-transparent bg-bg')}
      >
        <div className="container flex h-16 items-center gap-2 sm:gap-3">
          <button className="btn-icon -ml-2 lg:hidden" onClick={() => setMobileOpen(true)} aria-label="Open menu"><Menu size={22} /></button>
          <Logo />

          <button onClick={() => setSearchOpen(true)}
            className="mx-auto hidden h-11 w-full max-w-md items-center gap-3 rounded-full border border-line bg-surface px-4 text-sm text-ink-faint transition hover:border-ink/30 md:flex">
            <Search size={17} />
            <span className="flex-1 text-left">Search products, brands…</span>
            <kbd className="rounded-md border border-line px-1.5 py-0.5 text-[10px] font-semibold">⌘K</kbd>
          </button>

          <div className="ml-auto flex items-center md:ml-0">
            <button className="btn-icon md:hidden" onClick={() => setSearchOpen(true)} aria-label="Search"><Search size={20} /></button>
            <button className="btn-icon hidden sm:inline-flex" onClick={toggleTheme} aria-label="Toggle dark mode">
              <AnimatePresence mode="wait" initial={false}>
                <motion.span key={theme} initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }} transition={{ duration: 0.2 }}>
                  {theme === 'dark' ? <Sun size={19} /> : <Moon size={19} />}
                </motion.span>
              </AnimatePresence>
            </button>
            <Link to="/wishlist" className="btn-icon relative hidden sm:inline-flex" aria-label="Wishlist">
              <Heart size={20} />
              {wish.length > 0 && <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-deal" />}
            </Link>
            <button ref={cartIconRef} onClick={() => setCartOpen(true)} className="btn-icon relative" aria-label={`Cart, ${cart.total_items} items`}>
              <motion.span key={cartPulse} animate={cartPulse ? { scale: [1, 1.3, 0.9, 1.1, 1], rotate: [0, -12, 10, -4, 0] } : {}} transition={{ duration: 0.6 }}>
                <ShoppingBag size={20} />
              </motion.span>
              <AnimatePresence>
                {cart.total_items > 0 && (
                  <motion.span key={cart.total_items} initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 15 }}
                    className="absolute -right-0.5 -top-0.5 grid h-[18px] min-w-[18px] place-items-center rounded-full bg-brand px-1 text-[10px] font-bold text-brand-ink">
                    {cart.total_items}
                  </motion.span>
                )}
              </AnimatePresence>
            </button>
            <AccountMenu />
          </div>
        </div>

        <nav className="container hidden h-11 items-center gap-1 lg:flex" aria-label="Categories">
          {[{ slug: null, name: 'All' }, ...categories].map((c) => {
            const active = pathname === '/shop' && (c.slug ? activeCat === c.slug : !activeCat);
            return (
              <NavLink key={c.slug ?? 'all'} to={c.slug ? `/shop?category=${c.slug}` : '/shop'}
                className={cn('relative rounded-full px-3.5 py-1.5 text-[13px] font-medium transition', active ? 'text-ink' : 'text-ink-soft hover:text-ink')}>
                {active && <motion.span layoutId="cat-pill" className="absolute inset-0 rounded-full bg-muted" transition={{ type: 'spring', stiffness: 400, damping: 32 }} />}
                <span className="relative">{c.name}</span>
              </NavLink>
            );
          })}
          <Link to="/shop?sort_by=discount" className="ml-auto text-[13px] font-semibold text-deal">🔥 Deals</Link>
        </nav>
      </motion.header>

      <Drawer open={mobileOpen} onClose={() => setMobileOpen(false)} title="Menu" side="left" width="max-w-xs">
        <nav className="p-3">
          <Link to="/shop" className="block rounded-xl px-3 py-3 font-medium hover:bg-muted">All products</Link>
          {categories.map((c) => (
            <Link key={c.id} to={`/shop?category=${c.slug}`} className="flex items-center justify-between rounded-xl px-3 py-3 hover:bg-muted">
              <span className="font-medium">{c.name}</span><span className="text-xs text-ink-faint">{c.product_count}</span>
            </Link>
          ))}
          <div className="my-3 h-px bg-line" />
          <Link to="/shop?sort_by=discount" className="block rounded-xl px-3 py-3 font-semibold text-deal hover:bg-muted">🔥 Deals</Link>
          <Link to="/wishlist" className="block rounded-xl px-3 py-3 hover:bg-muted">Wishlist</Link>
          <Link to="/account/orders" className="block rounded-xl px-3 py-3 hover:bg-muted">My orders</Link>
          <button onClick={toggleTheme} className="flex w-full items-center gap-3 rounded-xl px-3 py-3 hover:bg-muted">
            {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />} {theme === 'dark' ? 'Light mode' : 'Dark mode'}
          </button>
        </nav>
      </Drawer>
    </>
  );
}
