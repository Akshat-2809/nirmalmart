import InfoPage, { useInfoLang } from '../components/InfoPage';
import { LegalSections } from '../components/LegalSections';
import { EMAIL, PHONE } from '../lib/contact';
import { PRIVACY_UPDATED } from './Privacy';

// Cancellation & refund policy — payment gateways check for this page before approving the store.
// It describes how cancellations, returns and refunds actually work in the shop (same rules as the
// backend). The refund timelines are the store's promise: change them here if Vilas changes them.
const T = {
  en: {
    eyebrow: 'Cancellations, returns and refunds',
    title: 'Refund & cancellation policy',
    intro: `How to cancel an order, return or exchange an item, and when you get your money back. Last updated ${PRIVACY_UPDATED}.`,
    sections: [
      ['Cancelling an order', [
        'You can cancel an order yourself any time before it is shipped: open My account → Orders, choose the order and tap Cancel order.',
        'Once an order has been shipped it can’t be cancelled. You can return it after delivery instead (see below).',
        'We may cancel an order if a product goes out of stock, if we can’t deliver to your pincode, or if we can’t confirm your payment. We’ll tell you, and refund anything you paid.',
      ]],
      ['Refunds for cancelled orders', [
        'If you had already paid, you get back the full amount, including any delivery charge.',
        'The refund is sent to the same UPI account you paid from, within 5–7 working days of the cancellation.',
      ]],
      ['Returns and exchanges', [
        'You can ask for a return or an exchange within 5 days of delivery, from My account → Orders → Return / exchange.',
        'Returns are accepted if an item is damaged, defective, wrong, incomplete, not as described or of poor quality — or if you simply no longer need it.',
        'Exchanges are for the same product, if the item is damaged, defective, the wrong size, wrong or incomplete. If a replacement isn’t available, we refund you instead.',
        'Please return the item unused, with its original packaging, tags and all accessories. Items that are damaged by misuse can’t be returned.',
        'We arrange the courier pickup from your address — you don’t pay for it.',
      ]],
      ['Refunds for returns', [
        'Once the returned item reaches us and passes a quick check, we refund the price of the returned items to the UPI account you paid from, within 5–7 working days.',
        'The original delivery charge (if any) isn’t refunded for returns.',
        'If the item fails the check (for example it was used or is missing parts), we’ll contact you and send it back.',
      ]],
      ['Damaged or wrong item?', [
        `Tell us within 5 days of delivery, with a photo if you can, through Return / exchange in your order, on WhatsApp (${PHONE.display}) or at ${EMAIL.support}. We’ll make it right with an exchange or a full refund.`,
      ]],
      ['Tracking your refund', [
        'Every order shows its cancellation, return and refund status in My account → Orders, including the refund reference once it has been sent.',
        'Banks can take 1–2 more working days to show a UPI refund. If you haven’t received it after that, contact us with your order number.',
      ]],
      ['Contact', [
        `Questions about a cancellation or refund: ${EMAIL.support}, or call / WhatsApp ${PHONE.display}.`,
      ]],
    ],
  },
  mr: {
    eyebrow: 'रद्द, परत आणि परतावा',
    title: 'परतावा व रद्द करण्याचे धोरण',
    intro: `ऑर्डर कशी रद्द करायची, वस्तू कशी परत किंवा बदलायची आणि पैसे कधी परत मिळतात. शेवटचा बदल: ${PRIVACY_UPDATED}.`,
    sections: [
      ['ऑर्डर रद्द करणे', [
        'ऑर्डर पाठवली जाण्यापूर्वी कधीही तुम्ही ती स्वतः रद्द करू शकता: माझे खाते → ऑर्डर्स उघडा, ऑर्डर निवडा आणि ‘ऑर्डर रद्द करा’ दाबा.',
        'ऑर्डर पाठवल्यानंतर ती रद्द करता येत नाही. त्याऐवजी डिलिव्हरीनंतर परत करू शकता (खाली पहा).',
        'उत्पादन संपल्यास, तुमच्या पिनकोडवर डिलिव्हरी शक्य नसल्यास किंवा पेमेंट निश्चित न झाल्यास आम्ही ऑर्डर रद्द करू शकतो. आम्ही तुम्हाला कळवू आणि भरलेली रक्कम परत करू.',
      ]],
      ['रद्द केलेल्या ऑर्डरचा परतावा', [
        'तुम्ही आधीच पैसे भरले असल्यास डिलिव्हरी शुल्कासह पूर्ण रक्कम परत मिळते.',
        'रद्द केल्यापासून 5–7 कामकाजाच्या दिवसांत परतावा ज्या UPI खात्यातून पैसे भरले त्यातच पाठवला जातो.',
      ]],
      ['परत आणि बदल', [
        'डिलिव्हरीनंतर 5 दिवसांत माझे खाते → ऑर्डर्स → परत / बदल येथून विनंती करू शकता.',
        'वस्तू खराब, सदोष, चुकीची, अपूर्ण, वर्णनाप्रमाणे नसलेली किंवा दर्जाहीन असल्यास — किंवा आता गरज नसल्यास — परत घेतली जाते.',
        'बदल त्याच उत्पादनासाठी आहे — खराब, सदोष, चुकीचा आकार, चुकीची किंवा अपूर्ण वस्तू असल्यास. दुसरी वस्तू उपलब्ध नसल्यास आम्ही पैसे परत करतो.',
        'वस्तू न वापरलेली, मूळ पॅकिंग, टॅग आणि सर्व अ‍ॅक्सेसरीजसह परत करा. गैरवापराने खराब झालेल्या वस्तू परत घेतल्या जात नाहीत.',
        'तुमच्या पत्त्यावरून कुरिअर पिकअप आम्ही करतो — त्यासाठी तुम्हाला पैसे द्यावे लागत नाहीत.',
      ]],
      ['परत केलेल्या वस्तूंचा परतावा', [
        'परत केलेली वस्तू आमच्याकडे पोहोचून तपासणीत योग्य आढळल्यावर, 5–7 कामकाजाच्या दिवसांत त्या वस्तूंची किंमत ज्या UPI खात्यातून भरले त्यात परत येते.',
        'परत करताना मूळ डिलिव्हरी शुल्क (असल्यास) परत मिळत नाही.',
        'तपासणीत वस्तू योग्य न आढळल्यास (उदा. वापरलेली किंवा भाग कमी), आम्ही तुम्हाला कळवू आणि वस्तू परत पाठवू.',
      ]],
      ['खराब किंवा चुकीची वस्तू मिळाली?', [
        `डिलिव्हरीनंतर 5 दिवसांत, शक्य असल्यास फोटोसह, ऑर्डरमधील परत / बदल, WhatsApp (${PHONE.display}) किंवा ${EMAIL.support} वर कळवा. आम्ही बदलून देऊ किंवा पूर्ण पैसे परत करू.`,
      ]],
      ['परतावा कुठपर्यंत आला ते पहा', [
        'प्रत्येक ऑर्डरमध्ये माझे खाते → ऑर्डर्स येथे रद्द, परत आणि परताव्याची स्थिती दिसते — परतावा पाठवल्यावर त्याचा संदर्भ क्रमांकही.',
        'बँकेला UPI परतावा दाखवायला आणखी 1–2 कामकाजाचे दिवस लागू शकतात. त्यानंतरही मिळाला नसल्यास ऑर्डर क्रमांकासह संपर्क करा.',
      ]],
      ['संपर्क', [
        `रद्द किंवा परताव्याबद्दल प्रश्न: ${EMAIL.support}, किंवा ${PHONE.display} वर कॉल / WhatsApp करा.`,
      ]],
    ],
  },
};

export default function Refunds() {
  const [lang, setLang] = useInfoLang();
  const t = T[lang];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <LegalSections key={lang} sections={t.sections} />
    </InfoPage>
  );
}
