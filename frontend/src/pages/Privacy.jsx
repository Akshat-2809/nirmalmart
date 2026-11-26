import InfoPage, { useInfoLang } from '../components/InfoPage';
import { LegalSections } from '../components/LegalSections';
import { EMAIL, PAYMENT, PHONE } from '../lib/contact';

// Plain-language privacy policy for the website and the Android app. Linked from the footer,
// the app's Account tab and the Play Store listing. Keep "Last updated" current when this changes.
export const PRIVACY_UPDATED = '26 November 2026';

const T = {
  en: {
    eyebrow: 'Your data, your choice',
    title: 'Privacy policy',
    intro: `How Nirmal Mart collects, uses and protects your information on nirmalmart.in and the Nirmal Mart app. Last updated ${PRIVACY_UPDATED}.`,
    sections: [
      ['What we collect', [
        'Account details: your name, email address, mobile number and password (stored only as a secure hash — we can never see it).',
        'Delivery addresses you save, and the address on each order.',
        'Orders: the products, amounts, payment status, delivery tracking and any return or exchange requests.',
        'Reviews you write, which show publicly with your name.',
        'Your bag and wishlist. If you are not signed in, these stay on your own device only.',
        'The pincode you enter to check delivery dates, kept on your device.',
        `If you sign up for offers, your email address. We send offers from ${EMAIL.promotions}, and every email has an unsubscribe link.`,
      ]],
      ['What we don’t collect', [
        'We don’t take card or bank details. You pay by UPI in your own UPI app; we only see the payment proof you choose to send us on WhatsApp.',
        'We don’t use advertising trackers, analytics tools or sell your data to anyone.',
        'The app doesn’t read your contacts, location, camera or files. It asks for photo access only on older phones, and only to save our UPI QR code when you tap “Save QR”.',
      ]],
      ['How we use it', [
        'To take, pack, deliver and track your orders, and to handle cancellations, returns and refunds.',
        'To contact you about your order by phone, WhatsApp or email — order updates, refunds and password-reset links.',
        'To keep your account, addresses, bag and wishlist in sync between the website and the app.',
        'To keep the shop secure and prevent misuse.',
      ]],
      ['Who we share it with', [
        `Courier partners (through Shiprocket): your name, phone and delivery address, so they can deliver and pick up parcels.`,
        'Our hosting providers, who store data for us under contract: Vercel (website), Render (servers) and Supabase (database and product images), in Singapore.',
        'Resend, which delivers our emails (order updates, password resets and offers you signed up for).',
        `WhatsApp: only the messages you choose to send us (for example payment proof to ${PAYMENT.waDisplay}).`,
        'Government authorities, only when the law requires it (for example GST records).',
      ]],
      ['How long we keep it', [
        'Your account data is kept while your account is open.',
        'Order records are kept for as long as Indian tax and accounting law requires (generally 8 years), even after an account is deleted — but without your name, phone or street address.',
      ]],
      ['Your choices', [
        'View and edit your name, mobile and addresses any time in My account.',
        'Delete your account yourself from My account → Password & security on the website, or Account → Delete account in the app. See the Delete your account page for details.',
        'Signing out removes your login from that device.',
      ]],
      ['Security', [
        'All traffic uses HTTPS. Passwords are hashed, logins use short-lived tokens, and only our staff can see orders in the admin panel.',
      ]],
      ['Children', [
        'Nirmal Mart is meant for adults. Please don’t create an account if you are under 18.',
      ]],
      ['Changes and contact', [
        'If we change this policy we’ll update the date at the top of this page.',
        `Questions or requests about your data: email ${EMAIL.support}, or call or WhatsApp us on ${PHONE.display}.`,
      ]],
    ],
  },
  mr: {
    eyebrow: 'तुमची माहिती, तुमचा निर्णय',
    title: 'गोपनीयता धोरण',
    intro: `nirmalmart.in आणि निर्मल मार्ट अ‍ॅपवर आम्ही तुमची माहिती कशी गोळा करतो, वापरतो आणि सुरक्षित ठेवतो. शेवटचा बदल: ${PRIVACY_UPDATED}.`,
    sections: [
      ['आम्ही काय गोळा करतो', [
        'खात्याची माहिती: नाव, ईमेल, मोबाईल नंबर आणि पासवर्ड (फक्त सुरक्षित स्वरूपात — आम्हालाही तो दिसत नाही).',
        'तुम्ही जतन केलेले डिलिव्हरी पत्ते आणि प्रत्येक ऑर्डरचा पत्ता.',
        'ऑर्डर्स: उत्पादने, रक्कम, पेमेंटची स्थिती, डिलिव्हरी ट्रॅकिंग आणि परत / बदलाच्या विनंत्या.',
        'तुम्ही लिहिलेले रिव्ह्यू, जे तुमच्या नावासह सर्वांना दिसतात.',
        'तुमची बॅग आणि विशलिस्ट. साइन इन नसल्यास त्या फक्त तुमच्या डिव्हाइसवर राहतात.',
        'डिलिव्हरीची तारीख पाहण्यासाठी टाकलेला पिनकोड, तुमच्या डिव्हाइसवर.',
        `ऑफर्ससाठी साइन अप केल्यास तुमचा ईमेल. आम्ही ${EMAIL.promotions} वरून ऑफर्स पाठवतो आणि प्रत्येक ईमेलमध्ये अनसबस्क्राइब लिंक असते.`,
      ]],
      ['आम्ही काय गोळा करत नाही', [
        'आम्ही कार्ड किंवा बँक तपशील घेत नाही. तुम्ही तुमच्या UPI अ‍ॅपमधून पैसे भरता; तुम्ही WhatsApp वर पाठवलेला पेमेंटचा पुरावाच आम्हाला दिसतो.',
        'आम्ही जाहिरात ट्रॅकर्स किंवा अ‍ॅनालिटिक्स वापरत नाही आणि तुमची माहिती कोणालाही विकत नाही.',
        'अ‍ॅप तुमचे संपर्क, लोकेशन, कॅमेरा किंवा फाइल्स वाचत नाही. जुन्या फोनवर ‘QR जतन करा’ दाबल्यावरच फोटो परवानगी मागते.',
      ]],
      ['आम्ही ती कशासाठी वापरतो', [
        'ऑर्डर घेणे, पॅक करणे, पोहोचवणे, ट्रॅक करणे आणि रद्द / परत / परताव्यासाठी.',
        'तुमच्या ऑर्डरबद्दल फोन, WhatsApp किंवा ईमेलवर संपर्क करण्यासाठी — ऑर्डर अपडेट्स, परतावा आणि पासवर्ड रीसेट लिंक.',
        'वेबसाइट आणि अ‍ॅपमध्ये तुमचे खाते, पत्ते, बॅग आणि विशलिस्ट एकसारखे ठेवण्यासाठी.',
        'दुकान सुरक्षित ठेवण्यासाठी आणि गैरवापर टाळण्यासाठी.',
      ]],
      ['आम्ही कोणाला देतो', [
        'कुरिअर भागीदार (Shiprocket मार्फत): पार्सल पोहोचवण्यासाठी आणि नेण्यासाठी नाव, फोन आणि पत्ता.',
        'आमचे होस्टिंग प्रदाते, जे करारानुसार आमच्यासाठी माहिती साठवतात: Vercel (वेबसाइट), Render (सर्व्हर) आणि Supabase (डेटाबेस व फोटो), सिंगापूरमध्ये.',
        'Resend, जे आमचे ईमेल पोहोचवते (ऑर्डर अपडेट्स, पासवर्ड रीसेट आणि तुम्ही मागितलेल्या ऑफर्स).',
        `WhatsApp: फक्त तुम्ही आम्हाला पाठवलेले संदेश (उदा. ${PAYMENT.waDisplay} वर पेमेंटचा पुरावा).`,
        'कायद्याने आवश्यक असल्यासच सरकारी यंत्रणा (उदा. GST नोंदी).',
      ]],
      ['आम्ही किती काळ ठेवतो', [
        'खाते चालू असेपर्यंत खात्याची माहिती ठेवली जाते.',
        'भारतीय कर कायद्यानुसार ऑर्डरच्या नोंदी (साधारण ८ वर्षे) ठेवल्या जातात — खाते हटवल्यानंतरही, पण तुमचे नाव, फोन व पत्त्याशिवाय.',
      ]],
      ['तुमचे पर्याय', [
        'माझे खाते मध्ये कधीही नाव, मोबाईल आणि पत्ते पहा व बदला.',
        'वेबसाइटवर माझे खाते → पासवर्ड व सुरक्षा, किंवा अ‍ॅपमध्ये खाते → खाते हटवा येथून तुम्ही स्वतः खाते हटवू शकता. तपशीलासाठी ‘खाते हटवा’ पान पहा.',
        'साइन आउट केल्यावर त्या डिव्हाइसवरून लॉगिन काढले जाते.',
      ]],
      ['सुरक्षा', ['सर्व माहिती HTTPS ने जाते. पासवर्ड सुरक्षित स्वरूपात ठेवले जातात आणि ऑर्डर्स फक्त आमच्या कर्मचाऱ्यांना दिसतात.']],
      ['मुले', ['निर्मल मार्ट प्रौढांसाठी आहे. तुमचे वय १८ पेक्षा कमी असल्यास खाते तयार करू नका.']],
      ['बदल आणि संपर्क', [
        'धोरण बदलल्यास आम्ही वरील तारीख बदलू.',
        `तुमच्या माहितीबद्दल प्रश्न किंवा विनंती: ${EMAIL.support} वर ईमेल करा, किंवा ${PHONE.display} वर कॉल / WhatsApp करा.`,
      ]],
    ],
  },
};

export default function Privacy() {
  const [lang, setLang] = useInfoLang();
  const t = T[lang];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <LegalSections key={lang} sections={t.sections} />
    </InfoPage>
  );
}
