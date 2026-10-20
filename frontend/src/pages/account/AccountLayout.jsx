import { motion } from 'framer-motion';
import { Heart, KeyRound, LogOut, MapPin, Package, User } from 'lucide-react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { cn } from '../../lib/cn';

const NAV = [
  ['/account', User, 'Profile', true],
  ['/account/orders', Package, 'Orders'],
  ['/account/addresses', MapPin, 'Addresses'],
  ['/wishlist', Heart, 'Wishlist'],
  ['/account/security', KeyRound, 'Password'],
];

export default function AccountLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  return (
    <div className="container py-10">
      <div className="mb-8 flex items-center gap-4">
        <motion.span initial={{ scale: 0.5, rotate: -20 }} animate={{ scale: 1, rotate: 0 }} transition={{ type: 'spring', stiffness: 260, damping: 14 }}
          className="grid h-14 w-14 place-items-center rounded-2xl bg-brand text-lg font-bold text-brand-ink shadow-glow">
          {user.full_name.split(' ').map((s) => s[0]).slice(0, 2).join('').toUpperCase()}
        </motion.span>
        <div>
          <h1 className="font-display text-2xl font-extrabold sm:text-3xl">Hi, {user.full_name.split(' ')[0]}</h1>
          <p className="text-sm text-ink-soft">{user.email}</p>
        </div>
      </div>
      <div className="grid gap-8 lg:grid-cols-[230px_1fr]">
        <nav className="no-scrollbar -mx-4 flex gap-1 overflow-x-auto px-4 lg:mx-0 lg:flex-col lg:px-0">
          {NAV.map(([to, Icon, label, end]) => (
            <NavLink key={to} to={to} end={end}
              className={({ isActive }) => cn('relative flex shrink-0 items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-medium transition', isActive ? 'text-ink' : 'text-ink-soft hover:text-ink')}>
              {({ isActive }) => (
                <>
                  {isActive && <motion.span layoutId="acct-nav" className="absolute inset-0 rounded-xl bg-muted" transition={{ type: 'spring', stiffness: 400, damping: 34 }} />}
                  <Icon size={17} className="relative" /><span className="relative">{label}</span>
                </>
              )}
            </NavLink>
          ))}
          <button onClick={() => { logout(); navigate('/'); }} className="flex shrink-0 items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-medium text-danger transition hover:bg-danger/10">
            <LogOut size={17} /> Sign out
          </button>
        </nav>
        <div className="min-w-0"><Outlet /></div>
      </div>
    </div>
  );
}
