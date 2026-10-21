import { motion } from 'framer-motion';
import { ArrowUpRight, MessageCircle, Phone } from 'lucide-react';
import { Link } from 'react-router-dom';
import InfoPage, { useInfoLang } from '../components/InfoPage';
import { fadeUp, Stagger } from '../components/ui/motion';
import { PHONE, SOCIAL } from '../lib/contact';

const T = {
  en: {
    eyebrow: 'We’re here to help',
    title: 'Contact us',
    intro: 'Questions about a product, your order or a delivery? Call or WhatsApp us and we’ll sort it out.',
    call: 'Call us', callNote: 'Tap to call',
    wa: 'WhatsApp', waNote: 'Chat with us — usually the quickest way to reach us',
    waText: 'Hi Nirmal Mart, I have a question about ',
    follow: 'Follow Nirmal Mart', followNote: 'New arrivals, offers and product videos.',
    orders: 'Looking for an order you placed?', track: 'Track your orders →',
  },
  mr: {
    eyebrow: 'आम्ही मदतीसाठी आहोत',
    title: 'संपर्क करा',
    intro: 'उत्पादन, ऑर्डर किंवा डिलिव्हरीबद्दल प्रश्न आहे? आम्हाला कॉल किंवा WhatsApp करा, आम्ही मदत करू.',
    call: 'कॉल करा', callNote: 'कॉल करण्यासाठी टॅप करा',
    wa: 'WhatsApp', waNote: 'आमच्याशी चॅट करा — संपर्काचा सर्वात जलद मार्ग',
    waText: 'नमस्कार Nirmal Mart, मला याबद्दल विचारायचे आहे: ',
    follow: 'Nirmal Mart ला फॉलो करा', followNote: 'नवीन उत्पादने, ऑफर्स आणि उत्पादनांचे व्हिडिओ.',
    orders: 'तुम्ही दिलेली ऑर्डर शोधत आहात?', track: 'तुमच्या ऑर्डर्स ट्रॅक करा →',
  },
};

export default function Contact() {
  const [lang, setLang] = useInfoLang();
  const t = T[lang];
  const ways = [
    { icon: Phone, title: t.call, note: t.callNote, href: `tel:${PHONE.tel}`, tone: 'bg-brand-soft text-brand' },
    { icon: MessageCircle, title: t.wa, note: t.waNote, href: `https://wa.me/${PHONE.wa}?text=${encodeURIComponent(t.waText)}`, external: true, tone: 'bg-[#25D366]/15 text-[#128C4B] dark:text-[#4ADE80]' },
  ];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <Stagger key={lang} className="mt-8 grid gap-4 sm:grid-cols-2">
        {ways.map(({ icon: Icon, title, note, href, external, tone }) => (
          <motion.a key={href} variants={fadeUp} href={href} {...(external && { target: '_blank', rel: 'noopener noreferrer' })}
            className="card group flex items-start gap-4 p-5 transition hover:-translate-y-0.5 hover:shadow-lift">
            <span className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl ${tone}`}><Icon size={22} /></span>
            <span className="min-w-0 flex-1">
              <span className="flex items-center gap-1 font-semibold">{title}
                <ArrowUpRight size={15} className="text-ink-faint transition group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-brand" /></span>
              <span className="mt-0.5 block font-display text-xl font-bold tracking-tight" lang="en">{PHONE.display}</span>
              <span className="mt-1 block text-sm text-ink-soft">{note}</span>
            </span>
          </motion.a>
        ))}
      </Stagger>

      <h2 className="mt-12 font-display text-xl font-bold">{t.follow}</h2>
      <p className="mt-1 text-sm text-ink-soft">{t.followNote}</p>
      <div className="mt-5 grid gap-3 sm:grid-cols-3">
        {SOCIAL.map(([name, Icon, url, handle]) => (
          <a key={name} href={url} target="_blank" rel="noopener noreferrer"
            className="card flex items-center gap-3 p-4 transition hover:border-brand/50 hover:shadow-soft">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-muted text-ink"><Icon size={19} /></span>
            <span className="min-w-0" lang="en">
              <span className="block text-sm font-semibold">{name}</span>
              <span className="block truncate text-xs text-ink-soft">{handle}</span>
            </span>
          </a>
        ))}
      </div>

      <div className="mt-12 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-muted px-5 py-4 text-sm">
        <span className="text-ink-soft">{t.orders}</span>
        <Link to="/account/orders" className="font-semibold text-brand hover:underline">{t.track}</Link>
      </div>
    </InfoPage>
  );
}
