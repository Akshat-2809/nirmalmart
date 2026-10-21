import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowRight, Instagram, Youtube, Facebook } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Link } from 'react-router-dom';
import { catalogApi } from '../../api';
import { Logo } from '../ui/bits';

// Google Play "play" mark (lucide has no store logos)
function PlayStore({ size = 17 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M4.6 2.2a1.3 1.3 0 0 0-.6 1.1v17.4c0 .5.2.9.6 1.1l9.6-9.8-9.6-9.8Zm10.8 11-2.3 2.3-7.1 7.2 9.7-5.4-.3-4.1Zm4.2-3.2-3-1.7-2.6 2.7 2.6 2.7 3-1.7c.9-.5.9-1.5 0-2Zm-14.6-9 7.1 7.2 2.3 2.3.3-4.1-9.7-5.4Z" />
    </svg>
  );
}

const SOCIAL = [
  ['Instagram', Instagram, 'https://www.instagram.com/nirmalmart09'],
  ['Facebook', Facebook, 'https://www.facebook.com/share/1GUyQxBTdf/'],
  ['YouTube', Youtube, 'https://www.youtube.com/@NirmalMart'],
];
// Set once the Android app is published; until then the icon shows as "coming soon"
const PLAY_STORE_URL = '';

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
            {SOCIAL.map(([name, Icon, url]) => (
              <motion.a key={name} href={url} target="_blank" rel="noopener noreferrer" whileHover={{ y: -3 }}
                className="btn-icon border border-line" aria-label={`Nirmal Mart on ${name}`} title={name}><Icon size={17} /></motion.a>
            ))}
            {PLAY_STORE_URL ? (
              <motion.a href={PLAY_STORE_URL} target="_blank" rel="noopener noreferrer" whileHover={{ y: -3 }}
                className="btn-icon border border-line" aria-label="Get the Nirmal Mart app on Google Play" title="Google Play"><PlayStore /></motion.a>
            ) : (
              <span className="btn-icon cursor-default border border-line opacity-60 hover:bg-transparent" title="Android app coming soon on Google Play"
                role="img" aria-label="Android app coming soon on Google Play"><PlayStore /></span>
            )}
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
