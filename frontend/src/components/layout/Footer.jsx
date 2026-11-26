import { useMutation, useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowRight } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Link } from 'react-router-dom';
import { catalogApi, newsletterApi } from '../../api';
import { errorMessage } from '../../api/client';
import { EMAIL, SOCIAL } from '../../lib/contact';
import { Logo } from '../ui/bits';

const STATIC_COLS = [
  { title: 'Account', links: [['My account', '/account'], ['Orders', '/account/orders'], ['Wishlist', '/wishlist'], ['Bag', '/cart']] },
  { title: 'Help', links: [['Shipping', '/shipping'], ['Returns', '/faq#returns'], ['Contact us', '/contact'], ['FAQs', '/faq'], ['Privacy policy', '/privacy'], ['Terms of use', '/terms'], ['Delete account', '/delete-account']] },
];

export default function Footer() {
  const [email, setEmail] = useState('');
  // Saved to the store's list of offer subscribers (admin → Subscribers)
  const subscribe = useMutation({
    mutationFn: newsletterApi.subscribe,
    onSuccess: (r) => { setEmail(''); r.status === 'already' ? toast(r.message, { icon: '💌' }) : toast.success(r.message); },
    onError: (e) => toast.error(errorMessage(e, 'Couldn’t sign you up — please try again')),
  });
  const { data: categories = [] } = useQuery({ queryKey: ['categories'], queryFn: catalogApi.categories, staleTime: 300_000 });
  const COLS = [
    { title: 'Shop', links: [['All products', '/shop'], ['🔥 Trending', '/shop?trending=true'],
      ...categories.slice(0, 5).map((c) => [c.name, `/shop?category=${c.slug}`]), ['Today’s Deals', '/shop?sort_by=discount']] },
    ...STATIC_COLS,
  ];
  return (
    <footer className="mt-20 border-t border-line bg-surface">
      <div className="container grid gap-12 py-14 lg:grid-cols-[1.3fr_2fr]">
        <div>
          <Logo />
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-ink-soft">
            Trending gadgets and everyday essentials at great prices — delivered to your door across Maharashtra.</p>
          <form className="mt-6 flex max-w-sm gap-2" onSubmit={(e) => { e.preventDefault(); if (!subscribe.isPending) subscribe.mutate(email.trim()); }}>
            <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Your email for offers" className="input rounded-full" aria-label="Email" />
            <motion.button whileTap={{ scale: 0.92 }} className="btn-dark h-11 w-11 shrink-0 px-0" aria-label="Subscribe" disabled={subscribe.isPending}>{subscribe.isPending ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-r-transparent" /> : <ArrowRight size={18} />}</motion.button>
          </form>
          <p className="mt-2 text-xs text-ink-faint">Offers and new arrivals, now and then. Unsubscribe anytime.</p>
          <div className="mt-6 flex gap-1">
            {SOCIAL.map(([name, Icon, url]) => (
              <motion.a key={name} href={url} target="_blank" rel="noopener noreferrer" whileHover={{ y: -3 }}
                className="btn-icon border border-line" aria-label={`Nirmal Mart on ${name}`} title={name}><Icon size={17} /></motion.a>
            ))}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-8 sm:grid-cols-3">
          {COLS.map((c) => (
            <div key={c.title}>
              <h4 className="mb-4 text-sm font-semibold">{c.title}</h4>
              <ul className="space-y-2.5">
                {c.links.map(([label, to]) => (
                  <li key={label}><Link to={to} className="text-sm text-ink-soft transition hover:text-brand">{label}</Link></li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
      <div className="border-t border-line">
        <div className="container flex flex-col items-center justify-between gap-3 py-6 text-xs text-ink-faint sm:flex-row">
          <p>© {new Date().getFullYear()} NirmalMart. All rights reserved. · <a href={`mailto:${EMAIL.support}`} className="hover:text-brand">{EMAIL.support}</a></p>
          <p className="flex items-center gap-3">
            <span>Secure checkout</span><span>·</span><span>Pay by UPI</span>
          </p>
        </div>
      </div>
    </footer>
  );
}
