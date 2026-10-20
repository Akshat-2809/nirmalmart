import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowRight, Instagram, Twitter, Youtube, Facebook } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Link } from 'react-router-dom';
import { catalogApi } from '../../api';
import { Logo } from '../ui/bits';

const STATIC_COLS = [
  { title: 'Account', links: [['My account', '/account'], ['Orders', '/account/orders'], ['Wishlist', '/wishlist'], ['Bag', '/cart']] },
  { title: 'Help', links: [['Shipping', '/shop'], ['Returns', '/shop'], ['Contact us', '/shop'], ['FAQs', '/shop']] },
];

export default function Footer() {
  const [email, setEmail] = useState('');
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
          <form className="mt-6 flex max-w-sm gap-2" onSubmit={(e) => { e.preventDefault(); setEmail(''); toast.success('You’re on the list!'); }}>
            <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Your email for offers" className="input rounded-full" aria-label="Email" />
            <motion.button whileTap={{ scale: 0.92 }} className="btn-dark h-11 w-11 shrink-0 px-0" aria-label="Subscribe"><ArrowRight size={18} /></motion.button>
          </form>
          <div className="mt-6 flex gap-1">
            {[Instagram, Twitter, Facebook, Youtube].map((Icon, i) => (
              <motion.a key={i} href="#" whileHover={{ y: -3 }} className="btn-icon border border-line" aria-label="Social link"><Icon size={17} /></motion.a>
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
          <p>© {new Date().getFullYear()} NirmalMart. All rights reserved.</p>
          <p className="flex items-center gap-3">
            <span>Secure payments</span><span>·</span><span>UPI</span><span>·</span><span>Cards</span><span>·</span><span>Net banking</span>
          </p>
        </div>
      </div>
    </footer>
  );
}
