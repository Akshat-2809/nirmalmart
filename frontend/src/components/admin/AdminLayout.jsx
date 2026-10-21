import { motion } from 'framer-motion';
import { FolderTree, LayoutDashboard, Menu, Moon, Package, Settings, ShoppingCart, Store, Sun, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import { NavLink, useLocation, useOutlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useUI } from '../../context/UIContext';
import { cn } from '../../lib/cn';
import { Logo } from '../ui/bits';
import { Drawer } from '../ui/Drawer';

const NAV = [
  ['/admin', LayoutDashboard, 'Dashboard', true],
  ['/admin/orders', ShoppingCart, 'Orders'],
  ['/admin/products', Package, 'Products'],
  ['/admin/categories', FolderTree, 'Categories'],
  ['/admin/customers', Users, 'Customers'],
  ['/admin/settings', Settings, 'Settings'],
];

function Nav() {
  return (
    <nav className="space-y-1">
      {NAV.map(([to, Icon, label, end]) => (
        <NavLink key={to} to={to} end={end}
          className={({ isActive }) => cn('relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition', isActive ? 'text-brand-ink' : 'text-ink-soft hover:bg-muted hover:text-ink')}>
          {({ isActive }) => (
            <>
              {isActive && <motion.span layoutId="admin-nav" className="absolute inset-0 rounded-xl bg-brand shadow-glow" transition={{ type: 'spring', stiffness: 400, damping: 34 }} />}
              <Icon size={18} className="relative" /><span className="relative">{label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );
}

export default function AdminLayout() {
  const { user } = useAuth();
  const { theme, toggleTheme } = useUI();
  const [open, setOpen] = useState(false);
  const location = useLocation();
  const outlet = useOutlet();
  useEffect(() => setOpen(false), [location.pathname]);

  return (
    <div className="min-h-screen bg-bg lg:grid lg:grid-cols-[250px_1fr]">
      <aside className="sticky top-0 hidden h-screen flex-col border-r border-line bg-surface p-5 lg:flex">
        <Logo to="/admin" />
        <p className="mb-6 mt-2 text-[11px] font-semibold uppercase tracking-widest text-ink-faint">Admin panel</p>
        <Nav />
        <NavLink to="/" className="mt-auto flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-ink-soft hover:bg-muted hover:text-ink"><Store size={18} /> View store</NavLink>
      </aside>

      <div className="min-w-0">
        <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-line bg-bg/80 px-4 backdrop-blur-xl sm:px-8">
          <button className="btn-icon -ml-2 lg:hidden" onClick={() => setOpen(true)} aria-label="Menu"><Menu size={20} /></button>
          <p className="text-sm text-ink-soft">Welcome back, <b className="text-ink">{user.full_name.split(' ')[0]}</b></p>
          <button className="btn-icon ml-auto" onClick={toggleTheme} aria-label="Toggle theme">{theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}</button>
        </header>
        <main className="p-4 sm:p-8">
          <motion.div key={location.pathname} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}>
            {outlet}
          </motion.div>
        </main>
      </div>

      <Drawer open={open} onClose={() => setOpen(false)} title="Admin" side="left" width="max-w-xs">
        <div className="p-4"><Nav /><NavLink to="/" className="mt-4 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-ink-soft"><Store size={18} /> View store</NavLink></div>
      </Drawer>
    </div>
  );
}

export function PageHead({ title, subtitle, children }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div><h1 className="font-display text-2xl font-extrabold sm:text-3xl">{title}</h1>{subtitle && <p className="mt-1 text-sm text-ink-soft">{subtitle}</p>}</div>
      {children && <div className="flex flex-wrap gap-2">{children}</div>}
    </div>
  );
}
