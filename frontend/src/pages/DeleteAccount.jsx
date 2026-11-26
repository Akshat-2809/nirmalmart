import { Link } from 'react-router-dom';
import DeleteAccountCard from '../components/DeleteAccountCard';
import InfoPage, { useInfoLang } from '../components/InfoPage';
import { LegalSections } from '../components/LegalSections';
import { useAuth } from '../context/AuthContext';
import { EMAIL, PHONE } from '../lib/contact';

// Public page about deleting a Nirmal Mart account — the web link the Play Store asks for.
// Signed-in customers can delete right here; others are sent to sign in first.
const T = {
  en: {
    eyebrow: 'Nirmal Mart account',
    title: 'Delete your account',
    intro: 'You can delete your Nirmal Mart account yourself, on the website or in the app.',
    sections: [
      ['How to delete it', [
        'Website: sign in, go to My account → Password & security, and choose Delete my account.',
        'App: open the Account tab and tap Delete account at the bottom.',
        'You’ll be asked for your password to confirm.',
        `Can’t sign in? Email ${EMAIL.support} from your registered email, or call / WhatsApp ${PHONE.display} from your registered mobile, and we’ll delete it for you.`,
      ]],
      ['What gets deleted', [
        'Your name, email address, mobile number and password.',
        'Your saved addresses, bag and wishlist.',
        'Your reviews stay on the products but show as “Customer” instead of your name.',
      ]],
      ['What we keep, and why', [
        'Records of past orders (products, amounts, dates, and the city, state and pincode) are kept for as long as Indian tax law requires, usually 8 years — without your name, phone or street address.',
        'Orders that are still on their way, waiting for a refund or being returned must finish first; we’ll tell you which ones.',
      ]],
    ],
    signin: 'Sign in to delete your account',
  },
  mr: {
    eyebrow: 'निर्मल मार्ट खाते',
    title: 'तुमचे खाते हटवा',
    intro: 'तुम्ही वेबसाइटवर किंवा अ‍ॅपमध्ये स्वतः तुमचे निर्मल मार्ट खाते हटवू शकता.',
    sections: [
      ['कसे हटवायचे', [
        'वेबसाइट: साइन इन करा, माझे खाते → पासवर्ड वर जा आणि ‘खाते हटवा’ निवडा.',
        'अ‍ॅप: खाते टॅब उघडा आणि खाली ‘खाते हटवा’ दाबा.',
        'निश्चित करण्यासाठी पासवर्ड विचारला जाईल.',
        `साइन इन करता येत नाही? नोंदणीकृत ईमेलवरून ${EMAIL.support} वर ईमेल करा, किंवा नोंदणीकृत मोबाईलवरून ${PHONE.display} वर कॉल / WhatsApp करा, आम्ही खाते हटवू.`,
      ]],
      ['काय हटवले जाते', [
        'तुमचे नाव, ईमेल, मोबाईल नंबर आणि पासवर्ड.',
        'जतन केलेले पत्ते, बॅग आणि विशलिस्ट.',
        'तुमचे रिव्ह्यू उत्पादनांवर राहतात, पण तुमच्या नावाऐवजी ‘Customer’ दिसते.',
      ]],
      ['आम्ही काय ठेवतो आणि का', [
        'जुन्या ऑर्डर्सच्या नोंदी (उत्पादने, रक्कम, तारखा आणि शहर, राज्य, पिनकोड) भारतीय कर कायद्यानुसार साधारण ८ वर्षे ठेवल्या जातात — तुमचे नाव, फोन व पत्त्याशिवाय.',
        'वाटेत असलेल्या, परतावा बाकी असलेल्या किंवा परत होत असलेल्या ऑर्डर्स आधी पूर्ण व्हाव्या लागतात; कोणत्या ते आम्ही सांगू.',
      ]],
    ],
    signin: 'खाते हटवण्यासाठी साइन इन करा',
  },
};

export default function DeleteAccount() {
  const [lang, setLang] = useInfoLang();
  const { user } = useAuth();
  const t = T[lang];
  return (
    <InfoPage lang={lang} setLang={setLang} eyebrow={t.eyebrow} title={t.title} intro={t.intro}>
      <LegalSections key={lang} sections={t.sections} />
      <div className="mt-6">
        {user
          ? <DeleteAccountCard />
          : <Link to="/login" state={{ from: '/account/security#delete' }} className="btn-primary">{t.signin}</Link>}
      </div>
    </InfoPage>
  );
}
