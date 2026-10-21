import { AnimatePresence, motion } from 'framer-motion';
import { ChevronDown } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import InfoPage, { useInfoLang } from '../components/InfoPage';
import { PHONE } from '../lib/contact';
import { cn } from '../lib/cn';

// [id, question, answer] — ids stay the same in both languages so links like /faq#returns work
const T = {
  en: {
    eyebrow: 'Help centre',
    title: 'Frequently asked questions',
    intro: 'Quick answers about delivery, payments, orders and returns.',
    more: 'Still have a question?', moreCta: 'Contact us',
    items: [
      ['delivery-time', 'How long does delivery take?', 'Orders usually arrive within 2–7 days. You can check the expected date for your pincode on any product page.'],
      ['delivery-charges', 'Is delivery free?', 'Yes, on orders of ₹499 and above. Orders below ₹499 have a ₹49 delivery charge.'],
      ['delivery-area', 'Where do you deliver?', 'We deliver across Maharashtra.'],
      ['payment', 'How can I pay?', 'You can pay online with UPI, debit or credit cards, net banking and wallets.'],
      ['tracking', 'How do I track my order?', 'Sign in and open Account → Orders. Each order shows its current status — confirmed, shipped or delivered.'],
      ['cancel', 'Can I cancel my order?', 'Yes, before it starts being processed. Open the order in Account → Orders and tap “Cancel order”. After that, call or WhatsApp us and we’ll help.'],
      ['returns', 'Can I return a product?', 'Most items can be returned within 7 days of delivery. Call or WhatsApp us with your order number and we’ll guide you.'],
      ['account', 'Do I need an account to order?', 'Yes — a free account lets you place orders, save addresses and track deliveries. You can browse and fill your bag without one.'],
      ['contact', 'How can I contact you?', `Call or WhatsApp us on ${PHONE.display}.`],
    ],
  },
  mr: {
    eyebrow: 'मदत केंद्र',
    title: 'नेहमी विचारले जाणारे प्रश्न',
    intro: 'डिलिव्हरी, पेमेंट, ऑर्डर आणि परताव्याबद्दल झटपट उत्तरे.',
    more: 'अजून काही प्रश्न आहे?', moreCta: 'संपर्क करा',
    items: [
      ['delivery-time', 'डिलिव्हरीला किती वेळ लागतो?', 'ऑर्डर्स साधारणपणे 2–7 दिवसांत पोहोचतात. तुमच्या पिनकोडसाठी अपेक्षित तारीख कोणत्याही उत्पादनाच्या पानावर पाहू शकता.'],
      ['delivery-charges', 'डिलिव्हरी मोफत आहे का?', 'हो, ₹499 आणि त्याहून अधिक रकमेच्या ऑर्डरवर. ₹499 पेक्षा कमी ऑर्डरवर ₹49 डिलिव्हरी शुल्क लागते.'],
      ['delivery-area', 'तुम्ही कुठे डिलिव्हरी करता?', 'आम्ही संपूर्ण महाराष्ट्रात डिलिव्हरी करतो.'],
      ['payment', 'पेमेंट कसे करता येते?', 'तुम्ही UPI, डेबिट/क्रेडिट कार्ड, नेट बँकिंग आणि वॉलेटद्वारे ऑनलाइन पेमेंट करू शकता.'],
      ['tracking', 'माझी ऑर्डर कशी ट्रॅक करू?', 'साइन इन करा आणि खाते → ऑर्डर्स उघडा. प्रत्येक ऑर्डरची सध्याची स्थिती — कन्फर्म, पाठवली किंवा डिलिव्हर झाली — तिथे दिसते.'],
      ['cancel', 'मी ऑर्डर रद्द करू शकतो का?', 'हो, ऑर्डरवर प्रक्रिया सुरू होण्यापूर्वी. खाते → ऑर्डर्स मध्ये ऑर्डर उघडा आणि “Cancel order” दाबा. त्यानंतर आम्हाला कॉल किंवा WhatsApp करा, आम्ही मदत करू.'],
      ['returns', 'उत्पादन परत करता येते का?', 'बहुतेक वस्तू डिलिव्हरीनंतर 7 दिवसांच्या आत परत करता येतात. तुमचा ऑर्डर नंबर घेऊन आम्हाला कॉल किंवा WhatsApp करा, आम्ही मार्गदर्शन करू.'],
      ['account', 'ऑर्डर करण्यासाठी खाते आवश्यक आहे का?', 'हो — मोफत खात्यामुळे ऑर्डर देणे, पत्ते सेव्ह करणे आणि डिलिव्हरी ट्रॅक करणे शक्य होते. खात्याशिवायही तुम्ही उत्पादने पाहू शकता आणि बॅगेत टाकू शकता.'],
      ['contact', 'तुमच्याशी संपर्क कसा साधायचा?', `${PHONE.display} वर कॉल किंवा WhatsApp करा.`],
    ],
  },
};

function Item({ id, q, a, open, onToggle }) {
  return (
    <div id={id} className={cn('card scroll-mt-28 transition', open && 'border-brand/40 shadow-soft')}>
      <h3>
        <button type="button" onClick={onToggle} aria-expanded={open} aria-controls={`${id}-a`}
          className="flex w-full items-center gap-4 px-5 py-4 text-left font-semibold">
          <span className="flex-1">{q}</span>
          <ChevronDown size={18} className={cn('shrink-0 text-ink-faint transition', open && 'rotate-180 text-brand')} />
        </button>
      </h3>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div id={`${id}-a`} initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25 }} className="overflow-hidden">
            <p className="px-5 pb-5 text-sm leading-relaxed text-ink-soft">{a}</p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function Faq() {
  const [lang, setLang] = useInfoLang();
  const { hash } = useLocation();
  const t = T[lang];
  const target = hash.slice(1);
  const [open, setOpen] = useState(() => new Set([t.items.some(([id]) => id === target) ? target : t.items[0][0]]));

  // Arriving from a link like /faq#returns: open that answer and bring it into view
  useEffect(() => {
    if (!target || !t.items.some(([id]) => id === target)) return;
    setOpen((s) => new Set(s).add(target));
    const timer = setTimeout(() => document.getElementById(target)?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 150);
    return () => clearTimeout(timer);
  }, [target]); // eslint-disable-line react-hooks/exhaustive-deps

  const toggle = (id) => setOpen((s) => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });

  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <div className="mt-8 space-y-3">
        {t.items.map(([id, q, a]) => <Item key={id} id={id} q={q} a={a} open={open.has(id)} onToggle={() => toggle(id)} />)}
      </div>
      <div className="mt-12 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-muted px-5 py-4 text-sm">
        <span className="text-ink-soft">{t.more}</span>
        <Link to="/contact" className="font-semibold text-brand hover:underline">{t.moreCta} →</Link>
      </div>
    </InfoPage>
  );
}
