import { motion } from 'framer-motion';
import { CheckCircle2, Clock, MapPin, Package, PackageCheck, Truck } from 'lucide-react';
import { Link } from 'react-router-dom';
import InfoPage, { useInfoLang } from '../components/InfoPage';
import { fadeUp, Stagger } from '../components/ui/motion';

const T = {
  en: {
    eyebrow: 'Shipping & delivery',
    title: 'Shipping information',
    intro: 'Everything you need to know about how your order reaches you.',
    facts: [
      [Clock, 'Delivery time', '2–7 days', 'Most orders arrive within 2 to 7 days of being placed. The exact time depends on your location.'],
      [Truck, 'Free delivery', 'On orders of ₹499+', 'Orders below ₹499 have a ₹49 delivery charge, shown in your bag before you pay.'],
      [MapPin, 'Where we deliver', 'Across Maharashtra', 'Enter your pincode on any product page to see the expected delivery date.'],
      [Package, 'Track your order', 'Account → Orders', 'See the status of every order, from confirmed to delivered.'],
    ],
    stepsTitle: 'How your order reaches you',
    steps: ['Order placed', 'Confirmed', 'Shipped', 'Delivered'],
    help: 'Order not arrived within 7 days?', helpCta: 'Contact us',
  },
  mr: {
    eyebrow: 'शिपिंग आणि डिलिव्हरी',
    title: 'डिलिव्हरीची माहिती',
    intro: 'तुमची ऑर्डर तुमच्यापर्यंत कशी पोहोचते, याची संपूर्ण माहिती.',
    facts: [
      [Clock, 'डिलिव्हरीचा कालावधी', '2–7 दिवस', 'बहुतेक ऑर्डर्स ऑर्डर दिल्यापासून 2 ते 7 दिवसांत पोहोचतात. नेमका वेळ तुमच्या ठिकाणावर अवलंबून असतो.'],
      [Truck, 'मोफत डिलिव्हरी', '₹499+ च्या ऑर्डरवर', '₹499 पेक्षा कमी रकमेच्या ऑर्डरवर ₹49 डिलिव्हरी शुल्क लागते, जे पेमेंटपूर्वी बॅगेत दिसते.'],
      [MapPin, 'आम्ही कुठे डिलिव्हरी करतो', 'संपूर्ण महाराष्ट्रात', 'अपेक्षित डिलिव्हरी तारीख पाहण्यासाठी कोणत्याही उत्पादनाच्या पानावर तुमचा पिनकोड टाका.'],
      [Package, 'ऑर्डर ट्रॅक करा', 'खाते → ऑर्डर्स', 'प्रत्येक ऑर्डरची स्थिती — कन्फर्म झाल्यापासून डिलिव्हर होईपर्यंत — तिथे पाहा.'],
    ],
    stepsTitle: 'तुमची ऑर्डर तुमच्यापर्यंत कशी पोहोचते',
    steps: ['ऑर्डर दिली', 'कन्फर्म झाली', 'पाठवली', 'डिलिव्हर झाली'],
    help: '7 दिवसांत ऑर्डर मिळाली नाही?', helpCta: 'संपर्क करा',
  },
};
const STEP_ICONS = [CheckCircle2, PackageCheck, Truck, MapPin];

export default function Shipping() {
  const [lang, setLang] = useInfoLang();
  const t = T[lang];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <Stagger key={lang} className="mt-8 grid gap-4 sm:grid-cols-2">
        {t.facts.map(([Icon, label, value, note]) => (
          <motion.div key={label} variants={fadeUp} className="card flex items-start gap-4 p-5">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand"><Icon size={22} /></span>
            <span className="min-w-0">
              <span className="block text-sm font-semibold text-ink-soft">{label}</span>
              <span className="mt-0.5 block font-display text-xl font-bold tracking-tight">{value}</span>
              <span className="mt-1 block text-sm leading-relaxed text-ink-soft">{note}</span>
            </span>
          </motion.div>
        ))}
      </Stagger>

      <h2 className="mt-12 font-display text-xl font-bold">{t.stepsTitle}</h2>
      <ol className="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {t.steps.map((s, i) => {
          const Icon = STEP_ICONS[i];
          return (
            <li key={s} className="card flex flex-col items-center gap-2 p-4 text-center">
              <span className="grid h-10 w-10 place-items-center rounded-full bg-muted text-brand"><Icon size={19} /></span>
              <span className="text-xs font-semibold text-ink-faint">{i + 1}</span>
              <span className="text-sm font-semibold">{s}</span>
            </li>
          );
        })}
      </ol>

      <div className="mt-12 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-muted px-5 py-4 text-sm">
        <span className="text-ink-soft">{t.help}</span>
        <Link to="/contact" className="font-semibold text-brand hover:underline">{t.helpCta} →</Link>
      </div>
    </InfoPage>
  );
}
