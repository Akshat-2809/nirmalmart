import { motion } from 'framer-motion';
import { ArrowUpRight, MessageCircle, Phone } from 'lucide-react';
import { Link } from 'react-router-dom';
import { PHONE, SOCIAL } from '../lib/contact';
import { fadeUp, Stagger } from '../components/ui/motion';

const WA_TEXT = encodeURIComponent('Hi Nirmal Mart, I have a question about ');

export default function Contact() {
  const ways = [
    { icon: Phone, title: 'Call us', text: PHONE.display, note: 'Tap to call', href: `tel:${PHONE.tel}`, tone: 'bg-brand-soft text-brand' },
    { icon: MessageCircle, title: 'WhatsApp', text: PHONE.display, note: 'Chat with us — usually the quickest way to reach us', href: `https://wa.me/${PHONE.wa}?text=${WA_TEXT}`, external: true, tone: 'bg-[#25D366]/15 text-[#128C4B] dark:text-[#4ADE80]' },
  ];
  return (
    <div className="container max-w-4xl py-10">
      <p className="eyebrow">We’re here to help</p>
      <h1 className="mt-2 font-display text-3xl font-extrabold sm:text-4xl">Contact us</h1>
      <p className="mt-2 max-w-xl text-ink-soft">
        Questions about a product, your order or a delivery? Call or WhatsApp us and we’ll sort it out.</p>

      <Stagger className="mt-8 grid gap-4 sm:grid-cols-2">
        {ways.map(({ icon: Icon, title, text, note, href, external, tone }) => (
          <motion.a key={title} variants={fadeUp} href={href} {...(external && { target: '_blank', rel: 'noopener noreferrer' })}
            className="card group flex items-start gap-4 p-5 transition hover:-translate-y-0.5 hover:shadow-lift">
            <span className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl ${tone}`}><Icon size={22} /></span>
            <span className="min-w-0 flex-1">
              <span className="flex items-center gap-1 font-semibold">{title}
                <ArrowUpRight size={15} className="text-ink-faint transition group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-brand" /></span>
              <span className="mt-0.5 block font-display text-xl font-bold tracking-tight">{text}</span>
              <span className="mt-1 block text-sm text-ink-soft">{note}</span>
            </span>
          </motion.a>
        ))}
      </Stagger>

      <h2 className="mt-12 font-display text-xl font-bold">Follow Nirmal Mart</h2>
      <p className="mt-1 text-sm text-ink-soft">New arrivals, offers and product videos.</p>
      <div className="mt-5 grid gap-3 sm:grid-cols-3">
        {SOCIAL.map(([name, Icon, url, handle]) => (
          <a key={name} href={url} target="_blank" rel="noopener noreferrer"
            className="card flex items-center gap-3 p-4 transition hover:border-brand/50 hover:shadow-soft">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-muted text-ink"><Icon size={19} /></span>
            <span className="min-w-0">
              <span className="block text-sm font-semibold">{name}</span>
              <span className="block truncate text-xs text-ink-soft">{handle}</span>
            </span>
          </a>
        ))}
      </div>

      <div className="mt-12 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-muted px-5 py-4 text-sm">
        <span className="text-ink-soft">Looking for an order you placed?</span>
        <Link to="/account/orders" className="font-semibold text-brand hover:underline">Track your orders →</Link>
      </div>
    </div>
  );
}
