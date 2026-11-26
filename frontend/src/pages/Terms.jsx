import InfoPage, { useInfoLang } from '../components/InfoPage';
import { LegalSections } from '../components/LegalSections';
import { EMAIL, PHONE } from '../lib/contact';
import { PRIVACY_UPDATED } from './Privacy';

// Terms of use for the website and the app. They describe how the shop actually works today
// (UPI QR payments, ₹49 delivery under ₹499, 5-day returns) — update them when that changes.
const T = {
  en: {
    eyebrow: 'The fine print, in plain words',
    title: 'Terms of use',
    intro: `The rules for shopping with Nirmal Mart on nirmalmart.in and the Nirmal Mart app. Last updated ${PRIVACY_UPDATED}.`,
    sections: [
      ['Your account', [
        'Give your real name, mobile number and delivery address so we can deliver your orders.',
        'Keep your password private. You’re responsible for orders placed from your account.',
        'You can delete your account at any time from My account.',
      ]],
      ['Prices and products', [
        'Prices are in Indian rupees and include GST.',
        'Product photos are for illustration; small differences in colour or packaging can happen.',
        'If a price or product detail is clearly wrong, we may cancel the order and refund any payment in full.',
      ]],
      ['Orders and payment', [
        'An order is confirmed once we’ve checked your UPI payment. Pay the exact amount shown and send the payment proof on WhatsApp as described on the order page.',
        'If we can’t confirm a payment, or a product runs out, we’ll cancel the order and refund anything you paid.',
      ]],
      ['Delivery', [
        'We deliver across Maharashtra, usually within 2–7 days. Delivery is free on orders of ₹499 or more; below that a ₹49 charge applies.',
        'Delivery dates shown are estimates from our courier partners.',
      ]],
      ['Cancellations, returns and refunds', [
        'You can cancel an order yourself until it’s shipped.',
        'You can ask for a return or exchange within 5 days of delivery if an item is damaged, defective, wrong or incomplete, or for the other reasons listed on the order page. We arrange the pickup.',
        'Refunds go back to the UPI account you paid from, once the returned item reaches us and is checked.',
      ]],
      ['Reviews', [
        'Reviews must be honest and about the product. We may remove reviews that are abusive, misleading or unrelated.',
      ]],
      ['Our responsibility', [
        'We do our best to keep the shop working and accurate, but we can’t promise it will always be available or error-free.',
        'Our responsibility for any order is limited to the amount you paid for it.',
      ]],
      ['Law and disputes', [
        'These terms follow Indian law. Courts in Maharashtra have jurisdiction.',
        `For any problem, contact us first on ${PHONE.display} or ${EMAIL.support} — we’ll try to sort it out quickly.`,
      ]],
    ],
  },
  mr: {
    eyebrow: 'नियम, सोप्या शब्दांत',
    title: 'वापराच्या अटी',
    intro: `nirmalmart.in आणि निर्मल मार्ट अ‍ॅपवर खरेदीचे नियम. शेवटचा बदल: ${PRIVACY_UPDATED}.`,
    sections: [
      ['तुमचे खाते', [
        'ऑर्डर पोहोचवता यावी म्हणून खरे नाव, मोबाईल नंबर आणि पत्ता द्या.',
        'पासवर्ड गुप्त ठेवा. तुमच्या खात्यातून दिलेल्या ऑर्डर्सची जबाबदारी तुमची आहे.',
        'तुम्ही कधीही माझे खाते मधून खाते हटवू शकता.',
      ]],
      ['किंमती आणि उत्पादने', [
        'किंमती भारतीय रुपयांत आणि GST सह आहेत.',
        'फोटो केवळ कल्पनेसाठी आहेत; रंग किंवा पॅकिंगमध्ये थोडा फरक असू शकतो.',
        'किंमत किंवा माहिती स्पष्टपणे चुकीची असल्यास आम्ही ऑर्डर रद्द करून पूर्ण रक्कम परत करू शकतो.',
      ]],
      ['ऑर्डर आणि पेमेंट', [
        'तुमचे UPI पेमेंट तपासल्यावर ऑर्डर निश्चित होते. दाखवलेली नेमकी रक्कम भरा आणि ऑर्डर पानावर सांगितल्याप्रमाणे WhatsApp वर पुरावा पाठवा.',
        'पेमेंट निश्चित न झाल्यास किंवा उत्पादन संपल्यास आम्ही ऑर्डर रद्द करून भरलेली रक्कम परत करू.',
      ]],
      ['डिलिव्हरी', [
        'आम्ही संपूर्ण महाराष्ट्रात साधारण २–७ दिवसांत पोहोचवतो. ₹499 किंवा जास्तच्या ऑर्डरवर डिलिव्हरी मोफत; त्यापेक्षा कमी असल्यास ₹49.',
        'दाखवलेल्या डिलिव्हरी तारखा कुरिअर भागीदारांचा अंदाज आहेत.',
      ]],
      ['रद्द, परत आणि परतावा', [
        'ऑर्डर पाठवली जाईपर्यंत तुम्ही ती स्वतः रद्द करू शकता.',
        'वस्तू खराब, सदोष, चुकीची किंवा अपूर्ण असल्यास, किंवा ऑर्डर पानावरील इतर कारणांसाठी, डिलिव्हरीनंतर ५ दिवसांत परत / बदल मागू शकता. पिकअप आम्ही करतो.',
        'परत आलेली वस्तू तपासल्यावर रक्कम ज्या UPI खात्यातून भरली त्यात परत येते.',
      ]],
      ['रिव्ह्यू', ['रिव्ह्यू प्रामाणिक आणि उत्पादनाबद्दल असावेत. अपमानास्पद, दिशाभूल करणारे किंवा असंबंधित रिव्ह्यू आम्ही काढू शकतो.']],
      ['आमची जबाबदारी', [
        'दुकान नीट चालवण्याचा आमचा प्रयत्न असतो, पण ते नेहमी उपलब्ध किंवा त्रुटीमुक्त असेल याची हमी देऊ शकत नाही.',
        'कोणत्याही ऑर्डरसाठी आमची जबाबदारी तुम्ही भरलेल्या रकमेपर्यंत मर्यादित आहे.',
      ]],
      ['कायदा आणि वाद', [
        'या अटी भारतीय कायद्यानुसार आहेत. महाराष्ट्रातील न्यायालयांना अधिकारक्षेत्र आहे.',
        `कोणतीही अडचण असल्यास आधी ${PHONE.display} किंवा ${EMAIL.support} वर संपर्क करा — आम्ही लवकर सोडवण्याचा प्रयत्न करू.`,
      ]],
    ],
  },
};

export default function Terms() {
  const [lang, setLang] = useInfoLang();
  const t = T[lang];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <LegalSections key={lang} sections={t.sections} />
    </InfoPage>
  );
}
