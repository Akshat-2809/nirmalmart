// Help pages shown inside the app: FAQs, shipping, refunds, privacy policy and terms.
// Generated from the website pages (frontend/src/pages/Faq.jsx, Shipping.jsx, Refunds.jsx, Privacy.jsx, Terms.jsx),
// except the FAQ answers about paying, tracking, cancelling and returns, which describe the app.
// When a website page changes, regenerate or change it here too.

typedef Faq = ({String id, String q, String a});
typedef ShippingFact = ({String icon, String title, String value, String body});
typedef LegalSection = ({String title, List<String> points});
typedef HelpContent = ({String faqIntro, List<Faq> faqs, String shippingIntro, List<ShippingFact> facts, String stepsTitle, List<String> steps, String lateHelp, String privacyIntro, List<LegalSection> privacy, String termsIntro, List<LegalSection> terms, String refundsIntro, List<LegalSection> refunds});

const helpContent = <String, HelpContent>{
  'en': (
    faqIntro: 'Quick answers about delivery, payments, orders and returns.',
    faqs: [
      (id: 'delivery-time', q: 'How long does delivery take?', a: 'Orders usually arrive within 2–7 days. You can check the expected date for your pincode on any product page.'),
      (id: 'delivery-charges', q: 'Is delivery free?', a: 'Yes, on orders of ₹499 and above. Orders below ₹499 have a ₹49 delivery charge.'),
      (id: 'delivery-area', q: 'Where do you deliver?', a: 'We deliver across Maharashtra.'),
      (id: 'payment', q: 'How can I pay?', a: 'Pay by UPI — Google Pay, PhonePe, Paytm, BHIM or any UPI app. After placing your order, tap “Pay with UPI app” or scan our QR, then send the payment proof on WhatsApp. We confirm your order once the payment is checked.'),
      (id: 'tracking', q: 'How do I track my order?', a: 'Open Account → My orders. Each order shows its status — confirmed, packed, shipped or delivered — and once it’s shipped, a Track button for the courier.'),
      (id: 'cancel', q: 'Can I cancel my order?', a: 'Yes, until it’s shipped. Open the order in Account → My orders and tap “Cancel order”. If you had already paid, the money goes back to the UPI account you paid from.'),
      (id: 'returns', q: 'Can I return or exchange a product?', a: 'Yes, within 5 days of delivery. Open the order in Account → My orders and tap Return / exchange, then choose the items and a reason. Our courier collects the item from your address. Returns are refunded to the UPI account you paid from once we receive the item (the delivery charge isn’t refunded). Exchanges are for the same item, for a wrong size or a defect.'),
      (id: 'account', q: 'Do I need an account to order?', a: 'Yes — a free account lets you place orders, save addresses and track deliveries. You can browse and fill your bag without one.'),
      (id: 'contact', q: 'How can I contact you?', a: 'Call or WhatsApp us on +91 74982 99375, or email support@nirmalmart.in.'),
    ],
    shippingIntro: 'Everything you need to know about how your order reaches you.',
    facts: [
      (icon: 'Clock', title: 'Delivery time', value: '2–7 days', body: 'Most orders arrive within 2 to 7 days of being placed. The exact time depends on your location.'),
      (icon: 'Truck', title: 'Free delivery', value: 'On orders of ₹499+', body: 'Orders below ₹499 have a ₹49 delivery charge, shown in your bag before you pay.'),
      (icon: 'MapPin', title: 'Where we deliver', value: 'Across Maharashtra', body: 'Enter your pincode on any product page to see the expected delivery date.'),
      (icon: 'Package', title: 'Track your order', value: 'Account → My orders', body: 'See the status of every order, from confirmed to delivered.'),
    ],
    stepsTitle: 'How your order reaches you',
    steps: ['Order placed', 'Confirmed', 'Shipped', 'Delivered'],
    lateHelp: 'Order not arrived within 7 days?',
    privacyIntro: 'How Nirmal Mart collects, uses and protects your information on nirmalmart.in and the Nirmal Mart app. Last updated 26 November 2026.',
    privacy: [
      (title: 'What we collect', points: [
        'Account details: your name, email address, mobile number and password (stored only as a secure hash — we can never see it).',
        'Delivery addresses you save, and the address on each order.',
        'Orders: the products, amounts, payment status, delivery tracking and any return or exchange requests.',
        'Reviews you write, which show publicly with your name.',
        'Your bag and wishlist. If you are not signed in, these stay on your own device only.',
        'The pincode you enter to check delivery dates, kept on your device.',
        'If you sign up for offers, your email address. We send offers from promotions@nirmalmart.in, and every email has an unsubscribe link.',
        'If you allow notifications in the app: a notification ID for your phone (from Google Firebase), the app’s language and your notification choices.',
      ]),
      (title: 'What we don’t collect', points: [
        'We don’t take card or bank details. You pay by UPI in your own UPI app; we only see the payment proof you choose to send us on WhatsApp.',
        'We don’t use advertising trackers, analytics tools or sell your data to anyone.',
        'The app doesn’t read your contacts, location, camera or files. It asks to show notifications, and asks for photo access only on older phones, and only to save our UPI QR code when you tap “Save QR”.',
      ]),
      (title: 'How we use it', points: [
        'To take, pack, deliver and track your orders, and to handle cancellations, returns and refunds.',
        'To contact you about your order by phone, WhatsApp or email — order updates, refunds and password-reset links.',
        'To keep your account, addresses, bag and wishlist in sync between the website and the app.',
        'To keep the shop secure and prevent misuse.',
      ]),
      (title: 'Who we share it with', points: [
        'Courier partners (through Shiprocket): your name, phone and delivery address, so they can deliver and pick up parcels.',
        'Our hosting providers, who store data for us under contract: Vercel (website), Render (servers) and Supabase (database and product images), in Singapore.',
        'Resend, which delivers our emails (order updates, password resets and offers you signed up for).',
        'Google Firebase, which delivers the app’s notifications (order updates, and offers if you leave them on).',
        'WhatsApp: only the messages you choose to send us (for example payment proof to +91 90222 30687).',
        'Government authorities, only when the law requires it (for example GST records).',
      ]),
      (title: 'How long we keep it', points: [
        'Your account data is kept while your account is open.',
        'Order records are kept for as long as Indian tax and accounting law requires (generally 8 years), even after an account is deleted — but without your name, phone or street address.',
      ]),
      (title: 'Your choices', points: [
        'View and edit your name, mobile and addresses any time in My account.',
        'Delete your account yourself from My account → Password & security on the website, or Account → Delete account in the app. See the Delete your account page for details.',
        'Turn order-update or offer notifications off any time in the app (Account → Settings) or in your phone’s settings.',
        'Signing out removes your login from that device, and order updates stop going to it.',
      ]),
      (title: 'Security', points: [
        'All traffic uses HTTPS. Passwords are hashed, logins use short-lived tokens, and only our staff can see orders in the admin panel.',
      ]),
      (title: 'Children', points: [
        'Nirmal Mart is meant for adults. Please don’t create an account if you are under 18.',
      ]),
      (title: 'Changes and contact', points: [
        'If we change this policy we’ll update the date at the top of this page.',
        'Questions or requests about your data: email support@nirmalmart.in, or call or WhatsApp us on +91 74982 99375.',
      ]),
    ],
    termsIntro: 'The rules for shopping with Nirmal Mart on nirmalmart.in and the Nirmal Mart app. Last updated 26 November 2026.',
    terms: [
      (title: 'Your account', points: [
        'Give your real name, mobile number and delivery address so we can deliver your orders.',
        'Keep your password private. You’re responsible for orders placed from your account.',
        'You can delete your account at any time from My account.',
      ]),
      (title: 'Prices and products', points: [
        'Prices are in Indian rupees and include GST.',
        'Product photos are for illustration; small differences in colour or packaging can happen.',
        'If a price or product detail is clearly wrong, we may cancel the order and refund any payment in full.',
      ]),
      (title: 'Orders and payment', points: [
        'An order is confirmed once we’ve checked your UPI payment. Pay the exact amount shown and send the payment proof on WhatsApp as described on the order page.',
        'If we can’t confirm a payment, or a product runs out, we’ll cancel the order and refund anything you paid.',
      ]),
      (title: 'Delivery', points: [
        'We deliver across Maharashtra, usually within 2–7 days. Delivery is free on orders of ₹499 or more; below that a ₹49 charge applies.',
        'Delivery dates shown are estimates from our courier partners.',
      ]),
      (title: 'Cancellations, returns and refunds', points: [
        'You can cancel an order yourself until it’s shipped.',
        'You can ask for a return or exchange within 5 days of delivery if an item is damaged, defective, wrong or incomplete, or for the other reasons listed on the order page. We arrange the pickup.',
        'Refunds go back to the UPI account you paid from, once the returned item reaches us and is checked.',
      ]),
      (title: 'Reviews', points: [
        'Reviews must be honest and about the product. We may remove reviews that are abusive, misleading or unrelated.',
      ]),
      (title: 'Our responsibility', points: [
        'We do our best to keep the shop working and accurate, but we can’t promise it will always be available or error-free.',
        'Our responsibility for any order is limited to the amount you paid for it.',
      ]),
      (title: 'Law and disputes', points: [
        'These terms follow Indian law. Courts in Maharashtra have jurisdiction.',
        'For any problem, contact us first on +91 74982 99375 or support@nirmalmart.in — we’ll try to sort it out quickly.',
      ]),
    ],
    refundsIntro: 'How to cancel an order, return or exchange an item, and when you get your money back. Last updated 26 November 2026.',
    refunds: [
      (title: 'Cancelling an order', points: [
        'You can cancel an order yourself any time before it is shipped: open Account → My orders, choose the order and tap Cancel order.',
        'Once an order has been shipped it can’t be cancelled. You can return it after delivery instead (see below).',
        'We may cancel an order if a product goes out of stock, if we can’t deliver to your pincode, or if we can’t confirm your payment. We’ll tell you, and refund anything you paid.',
      ]),
      (title: 'Refunds for cancelled orders', points: [
        'If you had already paid, you get back the full amount, including any delivery charge.',
        'The refund is sent to the same UPI account you paid from, within 5–7 working days of the cancellation.',
      ]),
      (title: 'Returns and exchanges', points: [
        'You can ask for a return or an exchange within 5 days of delivery, from Account → My orders → Return / exchange.',
        'Returns are accepted if an item is damaged, defective, wrong, incomplete, not as described or of poor quality — or if you simply no longer need it.',
        'Exchanges are for the same product, if the item is damaged, defective, the wrong size, wrong or incomplete. If a replacement isn’t available, we refund you instead.',
        'Please return the item unused, with its original packaging, tags and all accessories. Items that are damaged by misuse can’t be returned.',
        'We arrange the courier pickup from your address — you don’t pay for it.',
      ]),
      (title: 'Refunds for returns', points: [
        'Once the returned item reaches us and passes a quick check, we refund the price of the returned items to the UPI account you paid from, within 5–7 working days.',
        'The original delivery charge (if any) isn’t refunded for returns.',
        'If the item fails the check (for example it was used or is missing parts), we’ll contact you and send it back.',
      ]),
      (title: 'Damaged or wrong item?', points: [
        'Tell us within 5 days of delivery, with a photo if you can, through Return / exchange in your order, on WhatsApp (+91 74982 99375) or at support@nirmalmart.in. We’ll make it right with an exchange or a full refund.',
      ]),
      (title: 'Tracking your refund', points: [
        'Every order shows its cancellation, return and refund status in Account → My orders, including the refund reference once it has been sent.',
        'Banks can take 1–2 more working days to show a UPI refund. If you haven’t received it after that, contact us with your order number.',
      ]),
      (title: 'Contact', points: [
        'Questions about a cancellation or refund: support@nirmalmart.in, or call / WhatsApp +91 74982 99375.',
      ]),
    ],
  ),
  'mr': (
    faqIntro: 'डिलिव्हरी, पेमेंट, ऑर्डर आणि परताव्याबद्दल झटपट उत्तरे.',
    faqs: [
      (id: 'delivery-time', q: 'डिलिव्हरीला किती वेळ लागतो?', a: 'ऑर्डर्स साधारणपणे 2–7 दिवसांत पोहोचतात. तुमच्या पिनकोडसाठी अपेक्षित तारीख कोणत्याही उत्पादनाच्या पानावर पाहू शकता.'),
      (id: 'delivery-charges', q: 'डिलिव्हरी मोफत आहे का?', a: 'हो, ₹499 आणि त्याहून अधिक रकमेच्या ऑर्डरवर. ₹499 पेक्षा कमी ऑर्डरवर ₹49 डिलिव्हरी शुल्क लागते.'),
      (id: 'delivery-area', q: 'तुम्ही कुठे डिलिव्हरी करता?', a: 'आम्ही संपूर्ण महाराष्ट्रात डिलिव्हरी करतो.'),
      (id: 'payment', q: 'पेमेंट कसे करता येते?', a: 'UPI ने पेमेंट करा — Google Pay, PhonePe, Paytm, BHIM किंवा कोणतेही UPI अ‍ॅप. ऑर्डर दिल्यावर ‘UPI अ‍ॅपने पेमेंट’ दाबा किंवा आमचा QR स्कॅन करा, मग WhatsApp वर पेमेंटचा पुरावा पाठवा. पेमेंट तपासल्यावर आम्ही ऑर्डर निश्चित करतो.'),
      (id: 'tracking', q: 'माझी ऑर्डर कशी ट्रॅक करू?', a: 'खाते → माझ्या ऑर्डर्स उघडा. प्रत्येक ऑर्डरची स्थिती — निश्चित, पॅक, पाठवली किंवा पोहोचली — दिसते, आणि पाठवल्यावर कुरिअर ट्रॅक करण्याचे बटण.'),
      (id: 'cancel', q: 'मी ऑर्डर रद्द करू शकतो का?', a: 'हो, ऑर्डर पाठवली जाईपर्यंत. खाते → माझ्या ऑर्डर्स मध्ये ऑर्डर उघडा आणि ‘ऑर्डर रद्द करा’ दाबा. आधीच पैसे भरले असल्यास ते ज्या UPI खात्यातून भरले त्यात परत येतात.'),
      (id: 'returns', q: 'उत्पादन परत किंवा बदलून मिळू शकते का?', a: 'हो, डिलिव्हरीनंतर 5 दिवसांच्या आत. खाते → माझ्या ऑर्डर्स मध्ये ऑर्डर उघडा आणि ‘परत / बदल’ दाबा, नंतर वस्तू आणि कारण निवडा. आमचा कुरिअर वस्तू तुमच्या पत्त्यावरून घेऊन जाईल. वस्तू आमच्याकडे पोहोचल्यावर परतावा तुम्ही ज्या UPI खात्यातून पैसे भरले त्यात मिळेल (डिलिव्हरी शुल्क परत मिळत नाही). बदल फक्त त्याच वस्तूसाठी आहे — चुकीचा आकार किंवा दोष असल्यास.'),
      (id: 'account', q: 'ऑर्डर करण्यासाठी खाते आवश्यक आहे का?', a: 'हो — मोफत खात्यामुळे ऑर्डर देणे, पत्ते सेव्ह करणे आणि डिलिव्हरी ट्रॅक करणे शक्य होते. खात्याशिवायही तुम्ही उत्पादने पाहू शकता आणि बॅगेत टाकू शकता.'),
      (id: 'contact', q: 'तुमच्याशी संपर्क कसा साधायचा?', a: '+91 74982 99375 वर कॉल किंवा WhatsApp करा, किंवा support@nirmalmart.in वर ईमेल करा.'),
    ],
    shippingIntro: 'तुमची ऑर्डर तुमच्यापर्यंत कशी पोहोचते, याची संपूर्ण माहिती.',
    facts: [
      (icon: 'Clock', title: 'डिलिव्हरीचा कालावधी', value: '2–7 दिवस', body: 'बहुतेक ऑर्डर्स ऑर्डर दिल्यापासून 2 ते 7 दिवसांत पोहोचतात. नेमका वेळ तुमच्या ठिकाणावर अवलंबून असतो.'),
      (icon: 'Truck', title: 'मोफत डिलिव्हरी', value: '₹499+ च्या ऑर्डरवर', body: '₹499 पेक्षा कमी रकमेच्या ऑर्डरवर ₹49 डिलिव्हरी शुल्क लागते, जे पेमेंटपूर्वी बॅगेत दिसते.'),
      (icon: 'MapPin', title: 'आम्ही कुठे डिलिव्हरी करतो', value: 'संपूर्ण महाराष्ट्रात', body: 'अपेक्षित डिलिव्हरी तारीख पाहण्यासाठी कोणत्याही उत्पादनाच्या पानावर तुमचा पिनकोड टाका.'),
      (icon: 'Package', title: 'ऑर्डर ट्रॅक करा', value: 'खाते → माझ्या ऑर्डर्स', body: 'प्रत्येक ऑर्डरची स्थिती — कन्फर्म झाल्यापासून डिलिव्हर होईपर्यंत — तिथे पाहा.'),
    ],
    stepsTitle: 'तुमची ऑर्डर तुमच्यापर्यंत कशी पोहोचते',
    steps: ['ऑर्डर दिली', 'कन्फर्म झाली', 'पाठवली', 'डिलिव्हर झाली'],
    lateHelp: '7 दिवसांत ऑर्डर मिळाली नाही?',
    privacyIntro: 'nirmalmart.in आणि निर्मल मार्ट अ‍ॅपवर आम्ही तुमची माहिती कशी गोळा करतो, वापरतो आणि सुरक्षित ठेवतो. शेवटचा बदल: 26 November 2026.',
    privacy: [
      (title: 'आम्ही काय गोळा करतो', points: [
        'खात्याची माहिती: नाव, ईमेल, मोबाईल नंबर आणि पासवर्ड (फक्त सुरक्षित स्वरूपात — आम्हालाही तो दिसत नाही).',
        'तुम्ही जतन केलेले डिलिव्हरी पत्ते आणि प्रत्येक ऑर्डरचा पत्ता.',
        'ऑर्डर्स: उत्पादने, रक्कम, पेमेंटची स्थिती, डिलिव्हरी ट्रॅकिंग आणि परत / बदलाच्या विनंत्या.',
        'तुम्ही लिहिलेले रिव्ह्यू, जे तुमच्या नावासह सर्वांना दिसतात.',
        'तुमची बॅग आणि विशलिस्ट. साइन इन नसल्यास त्या फक्त तुमच्या डिव्हाइसवर राहतात.',
        'डिलिव्हरीची तारीख पाहण्यासाठी टाकलेला पिनकोड, तुमच्या डिव्हाइसवर.',
        'ऑफर्ससाठी साइन अप केल्यास तुमचा ईमेल. आम्ही promotions@nirmalmart.in वरून ऑफर्स पाठवतो आणि प्रत्येक ईमेलमध्ये अनसबस्क्राइब लिंक असते.',
        'अ‍ॅपमध्ये नोटिफिकेशन्सना परवानगी दिल्यास: तुमच्या फोनचा नोटिफिकेशन आयडी (Google Firebase कडून), अ‍ॅपची भाषा आणि तुमच्या नोटिफिकेशन निवडी.',
      ]),
      (title: 'आम्ही काय गोळा करत नाही', points: [
        'आम्ही कार्ड किंवा बँक तपशील घेत नाही. तुम्ही तुमच्या UPI अ‍ॅपमधून पैसे भरता; तुम्ही WhatsApp वर पाठवलेला पेमेंटचा पुरावाच आम्हाला दिसतो.',
        'आम्ही जाहिरात ट्रॅकर्स किंवा अ‍ॅनालिटिक्स वापरत नाही आणि तुमची माहिती कोणालाही विकत नाही.',
        'अ‍ॅप तुमचे संपर्क, लोकेशन, कॅमेरा किंवा फाइल्स वाचत नाही. ते नोटिफिकेशन्स दाखवण्याची परवानगी मागते, आणि जुन्या फोनवर ‘QR जतन करा’ दाबल्यावरच फोटो परवानगी मागते.',
      ]),
      (title: 'आम्ही ती कशासाठी वापरतो', points: [
        'ऑर्डर घेणे, पॅक करणे, पोहोचवणे, ट्रॅक करणे आणि रद्द / परत / परताव्यासाठी.',
        'तुमच्या ऑर्डरबद्दल फोन, WhatsApp किंवा ईमेलवर संपर्क करण्यासाठी — ऑर्डर अपडेट्स, परतावा आणि पासवर्ड रीसेट लिंक.',
        'वेबसाइट आणि अ‍ॅपमध्ये तुमचे खाते, पत्ते, बॅग आणि विशलिस्ट एकसारखे ठेवण्यासाठी.',
        'दुकान सुरक्षित ठेवण्यासाठी आणि गैरवापर टाळण्यासाठी.',
      ]),
      (title: 'आम्ही कोणाला देतो', points: [
        'कुरिअर भागीदार (Shiprocket मार्फत): पार्सल पोहोचवण्यासाठी आणि नेण्यासाठी नाव, फोन आणि पत्ता.',
        'आमचे होस्टिंग प्रदाते, जे करारानुसार आमच्यासाठी माहिती साठवतात: Vercel (वेबसाइट), Render (सर्व्हर) आणि Supabase (डेटाबेस व फोटो), सिंगापूरमध्ये.',
        'Resend, जे आमचे ईमेल पोहोचवते (ऑर्डर अपडेट्स, पासवर्ड रीसेट आणि तुम्ही मागितलेल्या ऑफर्स).',
        'Google Firebase, जे अ‍ॅपचे नोटिफिकेशन्स पोहोचवते (ऑर्डर अपडेट्स, आणि चालू ठेवल्यास ऑफर्स).',
        'WhatsApp: फक्त तुम्ही आम्हाला पाठवलेले संदेश (उदा. +91 90222 30687 वर पेमेंटचा पुरावा).',
        'कायद्याने आवश्यक असल्यासच सरकारी यंत्रणा (उदा. GST नोंदी).',
      ]),
      (title: 'आम्ही किती काळ ठेवतो', points: [
        'खाते चालू असेपर्यंत खात्याची माहिती ठेवली जाते.',
        'भारतीय कर कायद्यानुसार ऑर्डरच्या नोंदी (साधारण ८ वर्षे) ठेवल्या जातात — खाते हटवल्यानंतरही, पण तुमचे नाव, फोन व पत्त्याशिवाय.',
      ]),
      (title: 'तुमचे पर्याय', points: [
        'माझे खाते मध्ये कधीही नाव, मोबाईल आणि पत्ते पहा व बदला.',
        'वेबसाइटवर माझे खाते → पासवर्ड व सुरक्षा, किंवा अ‍ॅपमध्ये खाते → खाते हटवा येथून तुम्ही स्वतः खाते हटवू शकता. तपशीलासाठी ‘खाते हटवा’ पान पहा.',
        'ऑर्डर अपडेट्स किंवा ऑफर्सचे नोटिफिकेशन्स अ‍ॅपमध्ये (खाते → सेटिंग्ज) किंवा फोनच्या सेटिंग्जमध्ये कधीही बंद करा.',
        'साइन आउट केल्यावर त्या डिव्हाइसवरून लॉगिन काढले जाते आणि तिथे ऑर्डर अपडेट्स जाणे थांबते.',
      ]),
      (title: 'सुरक्षा', points: [
        'सर्व माहिती HTTPS ने जाते. पासवर्ड सुरक्षित स्वरूपात ठेवले जातात आणि ऑर्डर्स फक्त आमच्या कर्मचाऱ्यांना दिसतात.',
      ]),
      (title: 'मुले', points: [
        'निर्मल मार्ट प्रौढांसाठी आहे. तुमचे वय १८ पेक्षा कमी असल्यास खाते तयार करू नका.',
      ]),
      (title: 'बदल आणि संपर्क', points: [
        'धोरण बदलल्यास आम्ही वरील तारीख बदलू.',
        'तुमच्या माहितीबद्दल प्रश्न किंवा विनंती: support@nirmalmart.in वर ईमेल करा, किंवा +91 74982 99375 वर कॉल / WhatsApp करा.',
      ]),
    ],
    termsIntro: 'nirmalmart.in आणि निर्मल मार्ट अ‍ॅपवर खरेदीचे नियम. शेवटचा बदल: 26 November 2026.',
    terms: [
      (title: 'तुमचे खाते', points: [
        'ऑर्डर पोहोचवता यावी म्हणून खरे नाव, मोबाईल नंबर आणि पत्ता द्या.',
        'पासवर्ड गुप्त ठेवा. तुमच्या खात्यातून दिलेल्या ऑर्डर्सची जबाबदारी तुमची आहे.',
        'तुम्ही कधीही माझे खाते मधून खाते हटवू शकता.',
      ]),
      (title: 'किंमती आणि उत्पादने', points: [
        'किंमती भारतीय रुपयांत आणि GST सह आहेत.',
        'फोटो केवळ कल्पनेसाठी आहेत; रंग किंवा पॅकिंगमध्ये थोडा फरक असू शकतो.',
        'किंमत किंवा माहिती स्पष्टपणे चुकीची असल्यास आम्ही ऑर्डर रद्द करून पूर्ण रक्कम परत करू शकतो.',
      ]),
      (title: 'ऑर्डर आणि पेमेंट', points: [
        'तुमचे UPI पेमेंट तपासल्यावर ऑर्डर निश्चित होते. दाखवलेली नेमकी रक्कम भरा आणि ऑर्डर पानावर सांगितल्याप्रमाणे WhatsApp वर पुरावा पाठवा.',
        'पेमेंट निश्चित न झाल्यास किंवा उत्पादन संपल्यास आम्ही ऑर्डर रद्द करून भरलेली रक्कम परत करू.',
      ]),
      (title: 'डिलिव्हरी', points: [
        'आम्ही संपूर्ण महाराष्ट्रात साधारण २–७ दिवसांत पोहोचवतो. ₹499 किंवा जास्तच्या ऑर्डरवर डिलिव्हरी मोफत; त्यापेक्षा कमी असल्यास ₹49.',
        'दाखवलेल्या डिलिव्हरी तारखा कुरिअर भागीदारांचा अंदाज आहेत.',
      ]),
      (title: 'रद्द, परत आणि परतावा', points: [
        'ऑर्डर पाठवली जाईपर्यंत तुम्ही ती स्वतः रद्द करू शकता.',
        'वस्तू खराब, सदोष, चुकीची किंवा अपूर्ण असल्यास, किंवा ऑर्डर पानावरील इतर कारणांसाठी, डिलिव्हरीनंतर ५ दिवसांत परत / बदल मागू शकता. पिकअप आम्ही करतो.',
        'परत आलेली वस्तू तपासल्यावर रक्कम ज्या UPI खात्यातून भरली त्यात परत येते.',
      ]),
      (title: 'रिव्ह्यू', points: [
        'रिव्ह्यू प्रामाणिक आणि उत्पादनाबद्दल असावेत. अपमानास्पद, दिशाभूल करणारे किंवा असंबंधित रिव्ह्यू आम्ही काढू शकतो.',
      ]),
      (title: 'आमची जबाबदारी', points: [
        'दुकान नीट चालवण्याचा आमचा प्रयत्न असतो, पण ते नेहमी उपलब्ध किंवा त्रुटीमुक्त असेल याची हमी देऊ शकत नाही.',
        'कोणत्याही ऑर्डरसाठी आमची जबाबदारी तुम्ही भरलेल्या रकमेपर्यंत मर्यादित आहे.',
      ]),
      (title: 'कायदा आणि वाद', points: [
        'या अटी भारतीय कायद्यानुसार आहेत. महाराष्ट्रातील न्यायालयांना अधिकारक्षेत्र आहे.',
        'कोणतीही अडचण असल्यास आधी +91 74982 99375 किंवा support@nirmalmart.in वर संपर्क करा — आम्ही लवकर सोडवण्याचा प्रयत्न करू.',
      ]),
    ],
    refundsIntro: 'ऑर्डर कशी रद्द करायची, वस्तू कशी परत किंवा बदलायची आणि पैसे कधी परत मिळतात. शेवटचा बदल: 26 November 2026.',
    refunds: [
      (title: 'ऑर्डर रद्द करणे', points: [
        'ऑर्डर पाठवली जाण्यापूर्वी कधीही तुम्ही ती स्वतः रद्द करू शकता: खाते → माझ्या ऑर्डर्स उघडा, ऑर्डर निवडा आणि ‘ऑर्डर रद्द करा’ दाबा.',
        'ऑर्डर पाठवल्यानंतर ती रद्द करता येत नाही. त्याऐवजी डिलिव्हरीनंतर परत करू शकता (खाली पहा).',
        'उत्पादन संपल्यास, तुमच्या पिनकोडवर डिलिव्हरी शक्य नसल्यास किंवा पेमेंट निश्चित न झाल्यास आम्ही ऑर्डर रद्द करू शकतो. आम्ही तुम्हाला कळवू आणि भरलेली रक्कम परत करू.',
      ]),
      (title: 'रद्द केलेल्या ऑर्डरचा परतावा', points: [
        'तुम्ही आधीच पैसे भरले असल्यास डिलिव्हरी शुल्कासह पूर्ण रक्कम परत मिळते.',
        'रद्द केल्यापासून 5–7 कामकाजाच्या दिवसांत परतावा ज्या UPI खात्यातून पैसे भरले त्यातच पाठवला जातो.',
      ]),
      (title: 'परत आणि बदल', points: [
        'डिलिव्हरीनंतर 5 दिवसांत खाते → माझ्या ऑर्डर्स → परत / बदल येथून विनंती करू शकता.',
        'वस्तू खराब, सदोष, चुकीची, अपूर्ण, वर्णनाप्रमाणे नसलेली किंवा दर्जाहीन असल्यास — किंवा आता गरज नसल्यास — परत घेतली जाते.',
        'बदल त्याच उत्पादनासाठी आहे — खराब, सदोष, चुकीचा आकार, चुकीची किंवा अपूर्ण वस्तू असल्यास. दुसरी वस्तू उपलब्ध नसल्यास आम्ही पैसे परत करतो.',
        'वस्तू न वापरलेली, मूळ पॅकिंग, टॅग आणि सर्व अ‍ॅक्सेसरीजसह परत करा. गैरवापराने खराब झालेल्या वस्तू परत घेतल्या जात नाहीत.',
        'तुमच्या पत्त्यावरून कुरिअर पिकअप आम्ही करतो — त्यासाठी तुम्हाला पैसे द्यावे लागत नाहीत.',
      ]),
      (title: 'परत केलेल्या वस्तूंचा परतावा', points: [
        'परत केलेली वस्तू आमच्याकडे पोहोचून तपासणीत योग्य आढळल्यावर, 5–7 कामकाजाच्या दिवसांत त्या वस्तूंची किंमत ज्या UPI खात्यातून भरले त्यात परत येते.',
        'परत करताना मूळ डिलिव्हरी शुल्क (असल्यास) परत मिळत नाही.',
        'तपासणीत वस्तू योग्य न आढळल्यास (उदा. वापरलेली किंवा भाग कमी), आम्ही तुम्हाला कळवू आणि वस्तू परत पाठवू.',
      ]),
      (title: 'खराब किंवा चुकीची वस्तू मिळाली?', points: [
        'डिलिव्हरीनंतर 5 दिवसांत, शक्य असल्यास फोटोसह, ऑर्डरमधील परत / बदल, WhatsApp (+91 74982 99375) किंवा support@nirmalmart.in वर कळवा. आम्ही बदलून देऊ किंवा पूर्ण पैसे परत करू.',
      ]),
      (title: 'परतावा कुठपर्यंत आला ते पहा', points: [
        'प्रत्येक ऑर्डरमध्ये खाते → माझ्या ऑर्डर्स येथे रद्द, परत आणि परताव्याची स्थिती दिसते — परतावा पाठवल्यावर त्याचा संदर्भ क्रमांकही.',
        'बँकेला UPI परतावा दाखवायला आणखी 1–2 कामकाजाचे दिवस लागू शकतात. त्यानंतरही मिळाला नसल्यास ऑर्डर क्रमांकासह संपर्क करा.',
      ]),
      (title: 'संपर्क', points: [
        'रद्द किंवा परताव्याबद्दल प्रश्न: support@nirmalmart.in, किंवा +91 74982 99375 वर कॉल / WhatsApp करा.',
      ]),
    ],
  ),
};
