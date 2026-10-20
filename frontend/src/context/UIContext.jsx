import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { store } from '../lib/storage';

const UIContext = createContext(null);

export function UIProvider({ children }) {
  const [cartOpen, setCartOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [theme, setTheme] = useState(() => (document.documentElement.classList.contains('dark') ? 'dark' : 'light'));
  const [cartPulse, setCartPulse] = useState(0);
  const cartIconRef = useRef(null);

  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark');
    store.set('nm-theme', theme);
  }, [theme]);

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setSearchOpen((o) => !o);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  // Animates a copy of the product image flying into the header cart icon
  const flyToCart = useCallback((sourceEl) => {
    const target = cartIconRef.current;
    if (!sourceEl || !target || matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setCartPulse((n) => n + 1);
      return;
    }
    const from = sourceEl.getBoundingClientRect();
    const to = target.getBoundingClientRect();
    const ghost = sourceEl.cloneNode(true);
    Object.assign(ghost.style, {
      position: 'fixed', left: `${from.left}px`, top: `${from.top}px`, width: `${from.width}px`,
      height: `${from.height}px`, borderRadius: '16px', objectFit: 'cover', zIndex: 9999, pointerEvents: 'none',
      boxShadow: '0 20px 40px rgba(0,0,0,.25)',
    });
    document.body.appendChild(ghost);
    const dx = to.left + to.width / 2 - (from.left + from.width / 2);
    const dy = to.top + to.height / 2 - (from.top + from.height / 2);
    ghost.animate(
      [
        { transform: 'translate(0,0) scale(1)', opacity: 1 },
        { transform: `translate(${dx * 0.5}px, ${dy - 80}px) scale(0.45)`, opacity: 0.9, offset: 0.55 },
        { transform: `translate(${dx}px, ${dy}px) scale(0.08)`, opacity: 0.4 },
      ],
      { duration: 750, easing: 'cubic-bezier(.5,0,.3,1)' },
    ).onfinish = () => {
      ghost.remove();
      setCartPulse((n) => n + 1);
    };
  }, []);

  const value = useMemo(() => ({
    cartOpen, setCartOpen, searchOpen, setSearchOpen,
    theme, toggleTheme: () => setTheme((t) => (t === 'dark' ? 'light' : 'dark')),
    cartIconRef, flyToCart, cartPulse,
  }), [cartOpen, searchOpen, theme, flyToCart, cartPulse]);

  return <UIContext.Provider value={value}>{children}</UIContext.Provider>;
}

export const useUI = () => useContext(UIContext);
