import { AnimatePresence, motion } from 'framer-motion';
import { ChevronDown } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import InfoPage, { useInfoLang } from '../components/InfoPage';
import { EMAIL, PAYMENT, PHONE } from '../lib/contact';
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
      ['payment', 'How can I pay?', `By UPI. After you place your order, scan our QR code (or use our UPI ID) in any UPI app — Google Pay, PhonePe, Paytm or your bank’s app — and send a screenshot of the payment on WhatsApp to ${PAYMENT.waDisplay}. We confirm your order and start packing once we’ve checked the payment.`],
      ['tracking', 'How do I track my order?', 'Open My account → Orders. Each order shows its status — payment received, packed, shipped or delivered — and a courier tracking link once it ships. We also email you at each step, and the Nirmal Mart app sends a notification.'],
      ['cancel', 'Can I cancel my order?', 'Yes, any time before it is shipped. Open the order in My account → Orders and tap Cancel order. If you had already paid, the money goes back to the UPI account you paid from within 5–7 working days. Once shipped, an order can’t be cancelled, but you can return it after delivery.'],
      ['returns', 'Can I return or exchange a product?', 'Yes, within 5 days of delivery. Open the order in My account → Orders and tap Return / exchange, then choose the items and a reason. Our courier collects the item from your address for free. Once it reaches us, the refund goes to the UPI account you paid from within 5–7 working days (the delivery charge isn’t refunded). Exchanges are for the same product — if it is damaged, defective, the wrong size or wrong item.'],
      ['account', 'Do I need an account to order?', 'Yes — a free account lets you place orders, save addresses and track deliveries. You can browse and fill your bag without one.'],
      ['contact', 'How can I contact you?', `Call or WhatsApp us on ${PHONE.display}, or email ${EMAIL.support}.`],
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
      ['payment', 'पेमेंट कसे करता येते?', `UPI ने. ऑर्डर दिल्यानंतर कोणत्याही UPI अ‍ॅपमध्ये — Google Pay, PhonePe, Paytm किंवा तुमच्या बँकेचे अ‍ॅप — आमचा QR कोड स्कॅन करा (किंवा UPI आयडी वापरा) आणि पेमेंटचा स्क्रीनशॉट ${PAYMENT.waDisplay} वर WhatsApp करा. पेमेंट तपासल्यावर आम्ही ऑर्डर कन्फर्म करून पॅकिंग सुरू करतो.`],
      ['tracking', 'माझी ऑर्डर कशी ट्रॅक करू?', 'माझे खाते → ऑर्डर्स उघडा. प्रत्येक ऑर्डरची स्थिती — पेमेंट मिळाले, पॅक झाली, पाठवली किंवा पोहोचली — आणि पाठवल्यानंतर कुरिअर ट्रॅकिंग लिंक तिथे दिसते. प्रत्येक टप्प्यावर आम्ही ईमेल पाठवतो आणि निर्मल मार्ट अ‍ॅपवर नोटिफिकेशनही येते.'],
      ['cancel', 'मी ऑर्डर रद्द करू शकतो का?', 'हो, ऑर्डर पाठवली जाण्यापूर्वी कधीही. माझे खाते → ऑर्डर्स मध्ये ऑर्डर उघडा आणि ‘ऑर्डर रद्द करा’ दाबा. पैसे आधीच भरले असल्यास ते 5–7 कामकाजाच्या दिवसांत ज्या UPI खात्यातून भरले त्यात परत येतात. ऑर्डर पाठवल्यानंतर रद्द करता येत नाही, पण डिलिव्हरीनंतर परत करू शकता.'],
      ['returns', 'उत्पादन परत किंवा बदलून मिळू शकते का?', 'हो, डिलिव्हरीनंतर 5 दिवसांच्या आत. माझे खाते → ऑर्डर्स मध्ये ऑर्डर उघडा आणि ‘परत / बदल’ दाबा, नंतर वस्तू आणि कारण निवडा. आमचा कुरिअर वस्तू तुमच्या पत्त्यावरून मोफत घेऊन जाईल. वस्तू आमच्याकडे पोहोचल्यावर 5–7 कामकाजाच्या दिवसांत ज्या UPI खात्यातून पैसे भरले त्यात परतावा मिळेल (डिलिव्हरी शुल्क परत मिळत नाही). बदली फक्त त्याच उत्पादनासाठी आहे — खराब, सदोष, चुकीचा आकार किंवा चुकीची वस्तू असल्यास.'],
      ['account', 'ऑर्डर करण्यासाठी खाते आवश्यक आहे का?', 'हो — मोफत खात्यामुळे ऑर्डर देणे, पत्ते सेव्ह करणे आणि डिलिव्हरी ट्रॅक करणे शक्य होते. खात्याशिवायही तुम्ही उत्पादने पाहू शकता आणि बॅगेत टाकू शकता.'],
      ['contact', 'तुमच्याशी संपर्क कसा साधायचा?', `${PHONE.display} वर कॉल किंवा WhatsApp करा, किंवा ${EMAIL.support} वर ईमेल करा.`],
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
