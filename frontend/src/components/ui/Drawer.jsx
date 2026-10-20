import { AnimatePresence, motion } from 'framer-motion';
import { X } from 'lucide-react';
import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { cn } from '../../lib/cn';

function useLockScroll(open, onClose) {
  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKey = (e) => e.key === 'Escape' && onClose?.();
    window.addEventListener('keydown', onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener('keydown', onKey);
    };
  }, [open, onClose]);
}

export function Drawer({ open, onClose, title, side = 'right', width = 'max-w-md', children, footer }) {
  useLockScroll(open, onClose);
  const x = side === 'right' ? '100%' : '-100%';
  return createPortal(
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-50">
          <motion.div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]" onClick={onClose}
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
          <motion.aside
            role="dialog" aria-modal="true" aria-label={title}
            className={cn('absolute top-0 flex h-full w-full flex-col bg-surface shadow-2xl', width, side === 'right' ? 'right-0' : 'left-0')}
            initial={{ x }} animate={{ x: 0 }} exit={{ x }}
            transition={{ type: 'spring', damping: 32, stiffness: 320 }}
          >
            <header className="flex items-center justify-between border-b border-line px-5 py-4">
              <h2 className="font-display text-lg font-bold">{title}</h2>
              <button className="btn-icon" onClick={onClose} aria-label="Close"><X size={20} /></button>
            </header>
            <div className="flex-1 overflow-y-auto">{children}</div>
            {footer && <footer className="border-t border-line p-5">{footer}</footer>}
          </motion.aside>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}

export function Modal({ open, onClose, title, children, className }) {
  useLockScroll(open, onClose);
  return createPortal(
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-4">
          <motion.div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]" onClick={onClose}
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
          <motion.div
            role="dialog" aria-modal="true" aria-label={title}
            className={cn('relative w-full max-w-lg overflow-hidden rounded-t-3xl bg-surface shadow-2xl sm:rounded-3xl', className)}
            initial={{ opacity: 0, y: 40, scale: 0.97 }} animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 30, scale: 0.98 }} transition={{ type: 'spring', damping: 28, stiffness: 340 }}
          >
            {title && (
              <header className="flex items-center justify-between px-6 pt-5">
                <h2 className="font-display text-lg font-bold">{title}</h2>
                <button className="btn-icon -mr-2" onClick={onClose} aria-label="Close"><X size={20} /></button>
              </header>
            )}
            <div className="max-h-[80vh] overflow-y-auto p-6">{children}</div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
