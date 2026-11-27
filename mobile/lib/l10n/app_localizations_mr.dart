// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'निर्मल मार्ट';

  @override
  String get tabHome => 'होम';

  @override
  String get tabShop => 'खरेदी';

  @override
  String get tabWishlist => 'विशलिस्ट';

  @override
  String get tabAccount => 'खाते';

  @override
  String get welcomeGetStarted => 'पुढे चला';

  @override
  String get welcomeBrowseGuest => 'लॉगिन न करता ब्राउझ करा';

  @override
  String get authSkip => 'वगळा';

  @override
  String get authBack => 'मागे';

  @override
  String get loginTitle => 'पुन्हा स्वागत आहे';

  @override
  String get loginSub => 'खरेदी सुरू ठेवण्यासाठी साइन इन करा.';

  @override
  String get registerTitle => 'तुमचे खाते तयार करा';

  @override
  String get registerSub => 'यासाठी एक मिनिटही लागत नाही.';

  @override
  String get tabSignIn => 'साइन इन';

  @override
  String get tabCreateAccount => 'खाते तयार करा';

  @override
  String get fieldFullName => 'पूर्ण नाव';

  @override
  String get hintFullName => 'तुमचे नाव';

  @override
  String get fieldEmailOrUsername => 'ईमेल किंवा युजरनेम';

  @override
  String get fieldEmail => 'ईमेल';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get fieldMobile => 'मोबाईल नंबर';

  @override
  String get hintMobile => '१० अंकी नंबर';

  @override
  String get fieldPassword => 'पासवर्ड';

  @override
  String get hintPassword => 'तुमचा पासवर्ड';

  @override
  String get hintNewPassword => 'किमान ८ अक्षरे';

  @override
  String get showPassword => 'पासवर्ड दाखवा';

  @override
  String get hidePassword => 'पासवर्ड लपवा';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get newToNirmalMart => 'निर्मल मार्टवर नवीन आहात?';

  @override
  String get createAnAccount => 'खाते तयार करा';

  @override
  String get haveAccount => 'आधीच खाते आहे?';

  @override
  String get termsNote =>
      'खाते तयार करून तुम्ही निर्मल मार्टच्या अटी आणि गोपनीयता धोरणास सहमती देता.';

  @override
  String get errName => 'कृपया फक्त अक्षरे वापरून तुमचे नाव लिहा';

  @override
  String get errEmail => 'कृपया योग्य ईमेल लिहा';

  @override
  String get errLogin => 'कृपया तुमचा ईमेल किंवा युजरनेम लिहा';

  @override
  String get errMobile => 'कृपया ६–९ ने सुरू होणारा १० अंकी मोबाईल नंबर लिहा';

  @override
  String get errPasswordShort => 'पासवर्ड किमान ८ अक्षरांचा असावा';

  @override
  String get errPasswordEmpty => 'कृपया तुमचा पासवर्ड लिहा';

  @override
  String signedInWelcome(String name) {
    return 'पुन्हा स्वागत आहे, $name!';
  }

  @override
  String registeredWelcome(String name) {
    return 'निर्मल मार्टमध्ये स्वागत आहे, $name! 🎉';
  }

  @override
  String get strength0 => 'खूप कमकुवत';

  @override
  String get strength1 => 'कमकुवत';

  @override
  String get strength2 => 'ठीक';

  @override
  String get strength3 => 'चांगला';

  @override
  String get strength4 => 'मजबूत';

  @override
  String get strengthHint => '८+ अक्षरे, अंक आणि चिन्हे वापरा';

  @override
  String get forgotTitle => 'पासवर्ड विसरलात?';

  @override
  String get forgotBody =>
      'तुमच्या नोंदणीकृत मोबाईल नंबरवरून आम्हाला WhatsApp वर संदेश पाठवा, आम्ही पासवर्ड रीसेट करण्यात मदत करू. ईमेलद्वारे रीसेट लवकरच येत आहे.';

  @override
  String get forgotWhatsApp => 'WhatsApp वर संदेश पाठवा';

  @override
  String forgotWhatsAppText(String email) {
    return 'नमस्कार निर्मल मार्ट, मी माझा ॲप पासवर्ड विसरलो/विसरले. माझ्या खात्याचा ईमेल: $email';
  }

  @override
  String get whatsAppMissing => 'WhatsApp उघडता आले नाही';

  @override
  String get secureNote => 'तुमची माहिती आमच्याकडे सुरक्षित आहे';

  @override
  String get homeSearchHint => 'निर्मल मार्टमध्ये शोधा';

  @override
  String get homeDeliverTo => 'डिलिव्हरी:';

  @override
  String get homeAddPincode => 'पिनकोड टाका';

  @override
  String get homeBag => 'बॅग';

  @override
  String get offersLabel => 'ऑफर्स';

  @override
  String get promoTrendingBadge => 'आता ट्रेंडिंग';

  @override
  String get promoTrendingTitle => 'ट्रेंडिंग गॅझेट्स';

  @override
  String get promoTrendingAlt => 'Trending Gadgets';

  @override
  String promoUpTo(int pct) {
    return '$pct% पर्यंत सूट';
  }

  @override
  String get promoBudgetBadge => 'बजेट निवड';

  @override
  String get promoBudgetTitle => '₹999 पेक्षा कमी';

  @override
  String get promoBudgetAlt => 'Under ₹999';

  @override
  String promoBudgetLine(int count) {
    return '$count उत्तम गॅझेट्स';
  }

  @override
  String get promoCategoryBadge => 'विभागानुसार खरेदी';

  @override
  String promoFrom(String price) {
    return '$price पासून';
  }

  @override
  String get shopNow => 'आता खरेदी करा';

  @override
  String get dealsEndsIn => 'संपण्यास';

  @override
  String get seeAll => 'सर्व पहा';

  @override
  String get trendingAlt => 'Trending Gadgets';

  @override
  String get viewAll => 'सर्व पहा';

  @override
  String showMore(int count) {
    return 'आणखी दाखवा ($count बाकी)';
  }

  @override
  String get recentEyebrow => 'जिथे थांबलात तिथून पुढे';

  @override
  String get recentTitle => 'अलीकडे पाहिलेले';

  @override
  String get loadingSlow => 'नवीन ऑफर्स लोड होत आहेत…';

  @override
  String get loadError => 'दुकान लोड झाले नाही';

  @override
  String get loadErrorBody =>
      'कृपया इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get add => 'जोडा';

  @override
  String get addedToBag => 'बॅगमध्ये जोडले';

  @override
  String get viewBag => 'बॅग पहा';

  @override
  String get outOfStock => 'स्टॉक संपला';

  @override
  String get bestseller => 'बेस्टसेलर';

  @override
  String get savedToWishlist => 'विशलिस्टमध्ये जतन केले';

  @override
  String get removedFromWishlist => 'विशलिस्टमधून काढले';

  @override
  String get wishlistError => 'विशलिस्ट अपडेट झाली नाही';

  @override
  String get addToWishlist => 'विशलिस्टमध्ये जतन करा';

  @override
  String get removeFromWishlist => 'विशलिस्टमधून काढा';

  @override
  String get pincodeTitle => 'डिलिव्हरी कुठे करायची?';

  @override
  String get pincodeBody =>
      'तुमची ऑर्डर कधी पोहोचेल हे पाहण्यासाठी पिनकोड टाका.';

  @override
  String get pincodeField => 'पिनकोड';

  @override
  String get pincodeCheck => 'तपासा';

  @override
  String pincodeDeliveryBy(String date) {
    return '$date पर्यंत डिलिव्हरी';
  }

  @override
  String get pincodeUnserviceable => 'माफ करा, या पिनकोडवर अजून डिलिव्हरी नाही';

  @override
  String get pincodeInvalid => 'कृपया योग्य 6 अंकी पिनकोड टाका';

  @override
  String homeGreeting(String name) {
    return 'नमस्कार, $name';
  }

  @override
  String get homeGreetingGuest => 'नमस्कार';

  @override
  String get homeSearchFor => 'शोधा';

  @override
  String get catTitle => 'विभागानुसार खरेदी';

  @override
  String get catAlt => 'Shop by category';

  @override
  String get dodBadge => 'आजची खास ऑफर';

  @override
  String dodOnlyLeft(int count) {
    return 'फक्त $count शिल्लक';
  }

  @override
  String get dodSellingFast => 'झपाट्याने विकले जात आहे';

  @override
  String get moreDealsTitle => 'आजच्या आणखी ऑफर्स';

  @override
  String get moreDealsAlt => 'More deals for today';

  @override
  String get budgetTitle => 'बजेटनुसार खरेदी';

  @override
  String get budgetAlt => 'Shop by budget';

  @override
  String get budgetUnder => 'पेक्षा कमी';

  @override
  String get budgetPremium => 'प्रीमियम';

  @override
  String itemsCount(int count) {
    return '$count वस्तू';
  }

  @override
  String get trendingNow => 'आता ट्रेंडिंग';

  @override
  String get justForYou => 'तुमच्यासाठी खास';

  @override
  String get justForYouAlt => 'Just for you';

  @override
  String get madeWith => 'महाराष्ट्रात ❤️ ने बनवलेले';

  @override
  String youSave(String amount) {
    return '$amount ची बचत';
  }

  @override
  String offTag(int pct) {
    return '$pct% सूट';
  }

  @override
  String get addCaps => 'जोडा';

  @override
  String get removeOne => 'एक कमी करा';

  @override
  String get addOne => 'आणखी एक जोडा';

  @override
  String freeDeliveryMore(String amount) {
    return 'मोफत डिलिव्हरीसाठी आणखी $amount ची खरेदी करा';
  }

  @override
  String photoOf(int n, int total) {
    return 'फोटो $n / $total';
  }

  @override
  String get close => 'बंद करा';

  @override
  String get inclusiveTaxes => 'सर्व करांसह';

  @override
  String get inStock => 'स्टॉकमध्ये, पाठवण्यासाठी तयार';

  @override
  String hurryOnlyLeft(int count) {
    return 'लवकर करा — फक्त $count शिल्लक';
  }

  @override
  String get quantity => 'संख्या';

  @override
  String get benefitDelivery => '₹499 वर\nमोफत डिलिव्हरी';

  @override
  String get benefitReturns => '5 दिवसांत\nपरत / बदल';

  @override
  String get benefitSecure => 'सुरक्षित\nUPI पेमेंट';

  @override
  String get deliveryCheckTitle => 'डिलिव्हरीची तारीख तपासा';

  @override
  String get deliveryEnterPin => 'तुमचा पिनकोड टाका';

  @override
  String get deliveryChecking => 'तपासत आहे…';

  @override
  String get deliveryGetItBy => 'मिळेल:';

  @override
  String deliveringTo(String pin) {
    return '$pin वर डिलिव्हरी';
  }

  @override
  String get change => 'बदला';

  @override
  String get aboutProduct => 'उत्पादनाबद्दल';

  @override
  String get highlights => 'ठळक वैशिष्ट्ये';

  @override
  String get specifications => 'तपशील';

  @override
  String get ratingsReviews => 'रेटिंग आणि रिव्ह्यू';

  @override
  String get writeReview => 'रिव्ह्यू लिहा';

  @override
  String get signInToReview => 'रिव्ह्यूसाठी साइन इन करा';

  @override
  String get noReviewsYet => 'अजून रिव्ह्यू नाहीत';

  @override
  String get noReviewsBody => 'घेतले आहे? इतरांना कसे आहे ते सांगा.';

  @override
  String reviewsCount(int count) {
    return '$count रिव्ह्यू';
  }

  @override
  String get verifiedPurchase => 'खात्रीशीर खरेदी';

  @override
  String get reviewTapStars => 'रेटिंगसाठी स्टारवर टॅप करा';

  @override
  String get reviewPickStars => 'कृपया स्टार रेटिंग निवडा';

  @override
  String get star1 => 'वाईट';

  @override
  String get star2 => 'ठीक';

  @override
  String get star3 => 'चांगले';

  @override
  String get star4 => 'खूप चांगले';

  @override
  String get star5 => 'उत्कृष्ट';

  @override
  String get reviewTitle => 'शीर्षक (ऐच्छिक)';

  @override
  String get reviewComment => 'तुमचा रिव्ह्यू (ऐच्छिक)';

  @override
  String get postReview => 'रिव्ह्यू पोस्ट करा';

  @override
  String get reviewThanks => 'रिव्ह्यूबद्दल धन्यवाद!';

  @override
  String shareText(String name, String price, String link) {
    return '$name फक्त $price मध्ये — निर्मल मार्ट 🛒\n$link';
  }

  @override
  String get share => 'शेअर करा';

  @override
  String get topDeal => 'टॉप ऑफर';

  @override
  String get catTrendingChip => 'ट्रेंडिंग';

  @override
  String get newArrival => 'नवीन';

  @override
  String get beFirstToReview => 'पहिला रिव्ह्यू तुमचा असू द्या';

  @override
  String get youMayAlsoLike => 'तुम्हाला हेही आवडेल';

  @override
  String get addToBag => 'बॅगमध्ये जोडा';

  @override
  String get goToBag => 'बॅगमध्ये जा';

  @override
  String get buyNow => 'आता खरेदी करा';

  @override
  String get productGone => 'हे उत्पादन उपलब्ध नाही';

  @override
  String get productGoneBody =>
      'ते दुकानातून काढले गेले असेल. नवीन उत्पादने पहा.';

  @override
  String get backToShopping => 'खरेदी सुरू ठेवा';

  @override
  String get searchHint => 'इंग्रजी किंवा मराठीत शोधा';

  @override
  String get clearSearch => 'काढा';

  @override
  String get recentSearches => 'अलीकडील शोध';

  @override
  String get clearAll => 'सर्व काढा';

  @override
  String get popularNow => 'आता लोकप्रिय';

  @override
  String get browseCategories => 'विभाग पहा';

  @override
  String seeAllResultsFor(String q) {
    return '“$q” चे सर्व निकाल पहा';
  }

  @override
  String get useThisName => 'हे नाव शोधा';

  @override
  String resultsCount(int count) {
    return '$count निकाल';
  }

  @override
  String resultsFor(String q) {
    return '“$q” साठी';
  }

  @override
  String showingResultsFor(String q, String word) {
    return '“$q” साठी दाखवत आहोत: $word';
  }

  @override
  String get showingSimilar => 'मिळते-जुळते निकाल दाखवत आहोत';

  @override
  String noResultsFor(String q) {
    return '“$q” साठी काही सापडले नाही';
  }

  @override
  String get noResultsBody => 'स्पेलिंग तपासा किंवा सोपा शब्द वापरून पहा.';

  @override
  String get didYouMean => 'तुम्हाला हे म्हणायचे आहे का:';

  @override
  String get youMightLike => 'तुम्हाला हे आवडू शकेल';

  @override
  String get noFilterResults => 'या फिल्टरनुसार काही सापडले नाही';

  @override
  String get noFilterResultsBody => 'एखादा फिल्टर काढून पहा.';

  @override
  String get clearFilters => 'फिल्टर काढा';

  @override
  String get filterInStock => 'स्टॉकमध्ये';

  @override
  String under(String price) {
    return '$price पेक्षा कमी';
  }

  @override
  String get sortBy => 'यानुसार लावा';

  @override
  String get sortBest => 'सर्वोत्तम जुळणारे';

  @override
  String get sortPriceLow => 'किंमत: कमी ते जास्त';

  @override
  String get sortPriceHigh => 'किंमत: जास्त ते कमी';

  @override
  String get sortDiscount => 'सर्वाधिक सूट';

  @override
  String get sortNewest => 'नवीन';

  @override
  String get shopAlt => 'Shop';

  @override
  String get shopEmpty => 'इथे अजून काही नाही';

  @override
  String get shopEmptyBody => 'नवीन उत्पादने लवकरच येतील — बाकीचे दुकान पहा.';

  @override
  String get seeAllProducts => 'सर्व उत्पादने पहा';

  @override
  String productsCount(int count) {
    return '$count उत्पादने';
  }

  @override
  String get backToTop => 'वर जा';

  @override
  String get sortPopular => 'लोकप्रिय';

  @override
  String get filters => 'फिल्टर';

  @override
  String get allProducts => 'सर्व';

  @override
  String removeFilter(String name) {
    return '$name फिल्टर काढा';
  }

  @override
  String get viewGrid => 'ग्रिड दृश्य';

  @override
  String get viewList => 'यादी दृश्य';

  @override
  String get categoryLabel => 'विभाग';

  @override
  String get priceLabel => 'किंमत';

  @override
  String get brandLabel => 'ब्रँड';

  @override
  String get inStockOnly => 'फक्त स्टॉकमधील';

  @override
  String get reset => 'रीसेट';

  @override
  String get showResults => 'निकाल दाखवा';

  @override
  String get noProductsMatch => 'काही जुळत नाही';

  @override
  String showProducts(int count) {
    return '$count उत्पादने दाखवा';
  }

  @override
  String get myBag => 'माझी बॅग';

  @override
  String get myBagAlt => 'My bag';

  @override
  String get freeDeliveryUnlocked => 'वा! या ऑर्डरवर मोफत डिलिव्हरी';

  @override
  String get deliveryBy => '';

  @override
  String get lineSoldOut => 'स्टॉक संपला — पुढे जाण्यासाठी काढा';

  @override
  String lineOnlyLeft(int count) {
    return 'फक्त $count शिल्लक — संख्या कमी करा';
  }

  @override
  String percentOff(int pct) {
    return '$pct% सूट';
  }

  @override
  String get remove => 'काढा';

  @override
  String get removedFromBag => 'बॅगमधून काढले';

  @override
  String get undo => 'परत आणा';

  @override
  String get moveToWishlist => 'विशलिस्टमध्ये हलवा';

  @override
  String get movedToWishlist => 'विशलिस्टमध्ये हलवले';

  @override
  String get fixQuantity => 'शिल्लक इतके करा';

  @override
  String fillGapTitle(String amount) {
    return 'मोफत डिलिव्हरीसाठी आणखी $amount';
  }

  @override
  String get fillGapBody => 'यापैकी कोणतेही एक पुरेसे आहे';

  @override
  String get priceDetails => 'किंमत तपशील';

  @override
  String mrpItems(int count) {
    return 'MRP ($count वस्तू)';
  }

  @override
  String get discount => 'सूट';

  @override
  String get deliveryLabel => 'डिलिव्हरी';

  @override
  String get free => 'मोफत';

  @override
  String get total => 'एकूण';

  @override
  String includesGst(String amount) {
    return 'GST $amount समाविष्ट';
  }

  @override
  String savingOnOrder(String amount) {
    return 'या ऑर्डरवर तुमची $amount ची बचत';
  }

  @override
  String get secureCheckout => 'सुरक्षित चेकआउट';

  @override
  String get payByUpi => 'UPI ने पेमेंट';

  @override
  String get fiveDayReturns => '5 दिवसांत परत';

  @override
  String get fixBagFirst => 'चेकआउटपूर्वी काही वस्तू तपासा';

  @override
  String get viewDetails => 'तपशील पहा';

  @override
  String get checkout => 'चेकआउट';

  @override
  String get bagEmpty => 'तुमची बॅग रिकामी आहे';

  @override
  String get bagEmptyAlt => 'Your bag is empty';

  @override
  String get bagEmptyBody =>
      'ट्रेंडिंग गॅझेट्स आणि घरगुती वस्तू तुमची वाट पाहत आहेत.';

  @override
  String get startShopping => 'खरेदी सुरू करा';

  @override
  String inYourWishlist(int count) {
    return 'विशलिस्टमध्ये $count वस्तू';
  }

  @override
  String get view => 'पहा';

  @override
  String get checkoutAlt => 'Checkout';

  @override
  String get deliverToCaps => 'डिलिव्हरी पत्ता';

  @override
  String itemsCaps(int count) {
    return '$count वस्तू';
  }

  @override
  String get editBag => 'बॅग बदला';

  @override
  String get deliveryInstructions => 'डिलिव्हरीसाठी सूचना (ऐच्छिक)';

  @override
  String get paymentCaps => 'पेमेंट';

  @override
  String get upiApps => 'Google Pay, PhonePe, Paytm, BHIM…';

  @override
  String get payAfterPlacing =>
      'ऑर्डर दिल्यानंतर लगेच पेमेंट करा — इथूनच UPI अ‍ॅप उघडा किंवा QR स्कॅन करा.';

  @override
  String itemsLabel(int count) {
    return 'वस्तू ($count)';
  }

  @override
  String get youSavedLabel => 'तुमची बचत';

  @override
  String get toPay => 'भरायची रक्कम';

  @override
  String placeOrder(String amount) {
    return 'ऑर्डर द्या · $amount';
  }

  @override
  String get placingOrder => 'ऑर्डर देत आहोत…';

  @override
  String get agreeTerms => 'ऑर्डर देऊन तुम्ही अटी व गोपनीयता धोरण मान्य करता';

  @override
  String get orderFailed => 'ऑर्डर देता आली नाही. पुन्हा प्रयत्न करा.';

  @override
  String get addAddressFirst => 'पुढे जाण्यासाठी डिलिव्हरी पत्ता जोडा';

  @override
  String get addressesError => 'तुमचे पत्ते लोड झाले नाहीत';

  @override
  String get addDeliveryAddress => 'डिलिव्हरी पत्ता जोडा';

  @override
  String get chooseAddress => 'कुठे पाठवायचे';

  @override
  String get addNewAddress => 'नवीन पत्ता जोडा';

  @override
  String get newAddress => 'नवीन पत्ता';

  @override
  String get fieldLine1 => 'घर क्र., इमारत, रस्ता';

  @override
  String get fieldLine2 => 'परिसर, खूण (ऐच्छिक)';

  @override
  String get fieldCity => 'शहर';

  @override
  String get fieldState => 'राज्य';

  @override
  String get errLine1 => 'घर क्रमांक आणि रस्ता टाका';

  @override
  String get errCity => 'फक्त अक्षरांत शहराचे नाव टाका';

  @override
  String get errState => 'राज्य निवडा';

  @override
  String get labelHome => 'घर';

  @override
  String get labelWork => 'ऑफिस';

  @override
  String get labelOther => 'इतर';

  @override
  String get saveDeliverHere => 'जतन करा आणि इथे पाठवा';

  @override
  String get orderPlaced => 'ऑर्डर दिली!';

  @override
  String get orderPlacedPay =>
      'शेवटची पायरी — UPI ने पेमेंट करा आणि आम्हाला पुरावा पाठवा.';

  @override
  String get orderPlacedThanks =>
      'निर्मल मार्टमध्ये खरेदीबद्दल धन्यवाद. आम्ही तुम्हाला कळवत राहू.';

  @override
  String orderNumber(String number) {
    return 'ऑर्डर $number';
  }

  @override
  String get orderIdCopied => 'ऑर्डर आयडी कॉपी केला';

  @override
  String get viewOrder => 'ऑर्डर पहा';

  @override
  String get continueShopping => 'खरेदी सुरू ठेवा';

  @override
  String get paymentPending => 'पेमेंट बाकी';

  @override
  String payByUpi2(String amount) {
    return 'UPI ने $amount भरा';
  }

  @override
  String qrFor(String payee) {
    return '$payee साठी UPI QR कोड';
  }

  @override
  String get payWithUpiApp => 'UPI अ‍ॅपने पेमेंट';

  @override
  String get saveQr => 'QR गॅलरीत जतन करा';

  @override
  String get copyUpiId => 'UPI आयडी कॉपी करा';

  @override
  String get upiIdCopied => 'UPI आयडी कॉपी केला';

  @override
  String get noUpiApp => 'UPI अ‍ॅप सापडले नाही — QR स्कॅन करा किंवा जतन करा';

  @override
  String get qrSaved => 'QR गॅलरीत जतन केला — UPI अ‍ॅपमधून उघडा';

  @override
  String get qrNotSaved => 'QR जतन झाला नाही — फोटो परवानगी द्या';

  @override
  String get payStepsTitle => 'पेमेंट कसे करायचे';

  @override
  String payStep1(String amount) {
    return 'नेमके $amount भरा — ‘UPI अ‍ॅपने पेमेंट’ दाबा किंवा QR स्कॅन करा.';
  }

  @override
  String get payStep2 => 'यशस्वी पेमेंटचा स्क्रीनशॉट घ्या.';

  @override
  String get payStep3 => 'हिरवे बटण दाबा आणि WhatsApp मध्ये स्क्रीनशॉट जोडा.';

  @override
  String get utrHint => 'UPI संदर्भ / UTR क्र. (ऐच्छिक)';

  @override
  String get sendProof => 'WhatsApp वर पेमेंटचा पुरावा पाठवा';

  @override
  String sendProofNote(String number) {
    return '$number वर जाईल. पेमेंट तपासल्यावर आम्ही ऑर्डर निश्चित करू.';
  }

  @override
  String get beingPacked => 'पॅक होत आहे';

  @override
  String get buyAgain => 'पुन्हा खरेदी करा';

  @override
  String get buyAgainNone => 'या वस्तू सध्या संपल्या आहेत';

  @override
  String buyAgainSome(int count) {
    return '$count वस्तू जोडल्या — बाकी संपल्या आहेत';
  }

  @override
  String get cancelExchangeQ => 'हा बदल रद्द करायचा?';

  @override
  String get cancelReturnQ => 'हे परत करणे रद्द करायचे?';

  @override
  String get cancelRequestBody => 'कुरिअर पिकअपही रद्द होईल.';

  @override
  String get cancelNoChargeNote =>
      'या ऑर्डरचे पेमेंट झालेले नाही, त्यामुळे काहीही आकारले जाणार नाही.';

  @override
  String get cancelOrder => 'ऑर्डर रद्द करा';

  @override
  String get cancelPackedNote =>
      'तुमचे पार्सल पॅक झाले आहे. आता रद्द केल्यास कुरिअर पिकअपही रद्द होईल.';

  @override
  String cancelRefundNote(String amount) {
    return 'तुमचे $amount ज्या UPI खात्यातून भरले त्यात परत येतील.';
  }

  @override
  String get cancelRequest => 'विनंती रद्द करा';

  @override
  String get cancelledNothingCharged => 'रद्द · काहीही आकारले नाही';

  @override
  String cancelledOn(String date) {
    return '$date रोजी रद्द';
  }

  @override
  String cancelledRefundPending(String amount) {
    return 'रद्द · $amount परतावा येत आहे';
  }

  @override
  String cancelledRefunded(String amount) {
    return 'रद्द · $amount परत केले';
  }

  @override
  String deliveredOn(String date) {
    return '$date रोजी पोहोचले';
  }

  @override
  String deliveredReturnUntil(String date, String until) {
    return '$date रोजी पोहोचले · $until पर्यंत परत करता येईल';
  }

  @override
  String get deliveringToCaps => 'डिलिव्हरी पत्ता';

  @override
  String get details => 'तपशील';

  @override
  String get exchangeIt => 'बदलून घ्या';

  @override
  String get exchangeNote =>
      'आम्ही वस्तू घेऊन जाऊ आणि दुसरी पाठवू — कोणतेही जास्त शुल्क नाही.';

  @override
  String get exchangeRequested => 'बदलाची विनंती पाठवली — आम्ही संपर्क करू';

  @override
  String get exchangeWord => 'बदल';

  @override
  String helpMessage(String number) {
    return 'नमस्कार निर्मल मार्ट, मला माझ्या ऑर्डर $number बाबत मदत हवी आहे.';
  }

  @override
  String inReturn(int count) {
    return '$count परत';
  }

  @override
  String get keepIt => 'राहू द्या';

  @override
  String get keepOrder => 'ऑर्डर ठेवा';

  @override
  String get myOrders => 'माझ्या ऑर्डर्स';

  @override
  String get myOrdersAlt => 'My orders';

  @override
  String get needHelp => 'मदत हवी?';

  @override
  String get noOrders => 'अजून ऑर्डर नाहीत';

  @override
  String get noOrdersBody => 'तुम्ही ऑर्डर केल्यावर ती इथे दिसेल.';

  @override
  String get noOrdersHere => 'इथे काही नाही';

  @override
  String get onTheWay => 'वाटेत आहे';

  @override
  String get orderCancelled => 'ऑर्डर रद्द केली';

  @override
  String get orderConfirmedLine => 'ऑर्डर निश्चित · लवकरच पॅक करू';

  @override
  String get orderDetails => 'ऑर्डर तपशील';

  @override
  String get ordersActive => 'चालू';

  @override
  String ordersCount(int count) {
    return '$count ऑर्डर्स';
  }

  @override
  String paidBy(String method) {
    return 'पेमेंट: $method';
  }

  @override
  String get payNow => 'आता भरा';

  @override
  String payToConfirm(String amount) {
    return 'ऑर्डर निश्चित करण्यासाठी $amount भरा';
  }

  @override
  String get payToConfirmBody => 'UPI पेमेंट तपासल्यावर आम्ही पॅकिंग सुरू करू.';

  @override
  String get pickItemsAndReason => 'वस्तू आणि कारण निवडा';

  @override
  String get pickReason => 'कारण निवडा';

  @override
  String placedOn(String when) {
    return '$when रोजी दिली';
  }

  @override
  String plusMore(int count) {
    return '+$count आणखी';
  }

  @override
  String qtyPrice(int qty, String price) {
    return 'संख्या $qty · $price';
  }

  @override
  String get rateItems => 'रेटिंग द्या';

  @override
  String refundDone(String amount) {
    return '$amount तुमच्या UPI खात्यात परत केले';
  }

  @override
  String refundOnTheWay(String amount) {
    return '$amount परतावा तुमच्या UPI खात्यात येत आहे';
  }

  @override
  String refundToUpi(String amount) {
    return '$amount UPI ला परत';
  }

  @override
  String get requestCancelled => 'विनंती रद्द केली';

  @override
  String get requestExchange => 'बदल मागा';

  @override
  String get requestReturn => 'परत करण्याची विनंती';

  @override
  String get retApproved => 'मंजूर';

  @override
  String get retExchanged => 'बदलले';

  @override
  String get retPickedUp => 'घेऊन गेले';

  @override
  String get retPickupScheduled => 'पिकअप ठरले';

  @override
  String get retReceived => 'मिळाले';

  @override
  String get retRefunded => 'परत केले';

  @override
  String get retRejected => 'मंजूर नाही';

  @override
  String get retRequested => 'विनंती केली';

  @override
  String get returnCommentHint => 'आणखी काही सांगायचे आहे? (ऐच्छिक)';

  @override
  String get returnExchange => 'परत / बदल';

  @override
  String get returnForRefund => 'परत करा';

  @override
  String get returnInProgressLine => 'परत / बदल सुरू आहे';

  @override
  String returnNote(String amount) {
    return 'आम्ही तुमच्या पत्त्यावरून घेऊन जाऊ. आमच्याकडे पोहोचल्यावर $amount UPI ला परत येतील.';
  }

  @override
  String get returnNoteNoAmount =>
      'आम्ही तुमच्या पत्त्यावरून घेऊन जाऊ आणि पोहोचल्यावर पैसे परत करू.';

  @override
  String get returnRequested => 'परत करण्याची विनंती पाठवली — आम्ही संपर्क करू';

  @override
  String returnUntilDays(String date, int days) {
    return '$date पर्यंत परत / बदल · $days दिवस बाकी';
  }

  @override
  String returnUntilToday(String date) {
    return '$date पर्यंत परत / बदल · शेवटचा दिवस';
  }

  @override
  String get returnWord => 'परत';

  @override
  String get sendProofShort => 'पुरावा पाठवा';

  @override
  String get stAwaitingPayment => 'पेमेंट बाकी';

  @override
  String get stCancelled => 'रद्द';

  @override
  String get stConfirmed => 'निश्चित';

  @override
  String get stDelivered => 'पोहोचले';

  @override
  String get stPacked => 'पॅक केले';

  @override
  String get stRefundPending => 'परतावा बाकी';

  @override
  String get stRefunded => 'परत केले';

  @override
  String get stReturnInProgress => 'परत सुरू';

  @override
  String get stShipped => 'पाठवले';

  @override
  String get statusCaps => 'स्थिती';

  @override
  String get stepConfirmed => 'निश्चित';

  @override
  String get stepDelivered => 'पोहोचले';

  @override
  String get stepPacked => 'पॅक';

  @override
  String get stepPlaced => 'दिली';

  @override
  String get stepShipped => 'पाठवले';

  @override
  String get today => 'आज';

  @override
  String get track => 'ट्रॅक';

  @override
  String get trackPickup => 'पिकअप ट्रॅक करा';

  @override
  String get upiPending => 'UPI (बाकी)';

  @override
  String get whatsWrong => 'कारण काय?';

  @override
  String get whichItems => 'कोणत्या वस्तू?';

  @override
  String get whyCancel => 'तुम्ही का रद्द करत आहात?';

  @override
  String addedToBagCount(int count) {
    return '$count वस्तू बॅगमध्ये जोडल्या';
  }

  @override
  String get wishlistShareTitle => 'माझी निर्मल मार्ट विशलिस्ट 🛒';

  @override
  String get wishlistGuest =>
      'फक्त या फोनवर जतन. सर्व डिव्हाइसवर ठेवण्यासाठी साइन इन करा.';

  @override
  String priceDropBanner(int count) {
    return '$count वस्तू जतन केल्यापेक्षा स्वस्त झाल्या';
  }

  @override
  String get wishlistAlt => 'Wishlist';

  @override
  String savedCount(int count) {
    return '$count जतन';
  }

  @override
  String get addAllToBag => 'सर्व बॅगमध्ये जोडा';

  @override
  String get movedToBag => 'बॅगमध्ये हलवले';

  @override
  String get inYourBag => 'बॅगमध्ये आहे';

  @override
  String get moveToBag => 'बॅगमध्ये हलवा';

  @override
  String priceDropped(String amount) {
    return 'किंमत $amount ने कमी';
  }

  @override
  String get wishlistEmpty => 'अजून काही जतन केले नाही';

  @override
  String get wishlistEmptyBody =>
      'कोणत्याही उत्पादनावरील ♡ दाबा आणि नंतरसाठी इथे जतन करा.';

  @override
  String get exploreProducts => 'उत्पादने पहा';

  @override
  String get accountCaps => 'खाते';

  @override
  String get accountDeleted => 'तुमचे खाते हटवले';

  @override
  String get accountGuestBody =>
      'ऑर्डर ट्रॅक करण्यासाठी आणि बॅग व विशलिस्ट सर्व डिव्हाइसवर ठेवण्यासाठी साइन इन करा.';

  @override
  String get accountHello => 'नमस्कार!';

  @override
  String get addressDeleted => 'पत्ता काढला';

  @override
  String get addressesTile => 'पत्ते';

  @override
  String get appearance => 'दिसणे';

  @override
  String awaitingPaymentCount(int count) {
    return '$count ऑर्डरचे पेमेंट बाकी';
  }

  @override
  String get cancel => 'रद्द';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String get confirmNewPassword => 'नवीन पासवर्ड पुन्हा टाका';

  @override
  String get currentPassword => 'सध्याचा पासवर्ड';

  @override
  String get defaultSet => 'मुख्य पत्ता बदलला';

  @override
  String get defaultTag => 'मुख्य';

  @override
  String get deleteAccount => 'खाते हटवा';

  @override
  String get deleteAccountQ => 'तुमचे खाते हटवायचे?';

  @override
  String get deleteAccountSub => 'तुमचे खाते कायमचे काढा';

  @override
  String get deleteAddressQ => 'हा पत्ता काढायचा?';

  @override
  String get deleteEnterPassword => 'निश्चित करण्यासाठी पासवर्ड टाका';

  @override
  String get deleteKeepsOrders =>
      'GST आणि परताव्यासाठी ऑर्डरच्या नोंदी तुमच्या संपर्क तपशीलाशिवाय ठेवल्या जातात. वाटेत असलेल्या ऑर्डर्स आधी पोहोचल्या किंवा रद्द झाल्या पाहिजेत.';

  @override
  String get deleteMyAccount => 'माझे खाते हटवा';

  @override
  String get deletePoint1 =>
      'तुमचे नाव, ईमेल, मोबाईल, पत्ते, बॅग आणि विशलिस्ट पुसले जातील.';

  @override
  String get deletePoint2 =>
      'तुम्ही साइन आउट व्हाल आणि या खात्यात पुन्हा साइन इन करता येणार नाही.';

  @override
  String get deletePoint3 =>
      'हे परत करता येणार नाही. नंतर त्याच ईमेलने नवीन खाते तयार करता येईल.';

  @override
  String get edit => 'बदला';

  @override
  String get editAddress => 'पत्ता बदला';

  @override
  String get editProfile => 'प्रोफाइल बदला';

  @override
  String get emailCantChange => 'ईमेल बदलता येत नाही';

  @override
  String get enterCurrentPassword => 'सध्याचा पासवर्ड टाका';

  @override
  String get faqs => 'प्रश्नोत्तरे';

  @override
  String get helpCaps => 'मदत';

  @override
  String get helpGeneral => 'नमस्कार निर्मल मार्ट, मला एक प्रश्न आहे.';

  @override
  String get keepMyAccount => 'खाते ठेवा';

  @override
  String get language => 'भाषा';

  @override
  String get makeDefault => 'मुख्य करा';

  @override
  String get myStuffCaps => 'माझे';

  @override
  String get newPassword => 'नवीन पासवर्ड';

  @override
  String get noAddressesBody => 'आताच जोडा, चेकआउट लवकर होईल.';

  @override
  String get noAddressesYet => 'जतन केलेले पत्ते नाहीत';

  @override
  String get ordersTile => 'ऑर्डर्स';

  @override
  String get passwordUpdated => 'पासवर्ड बदलला';

  @override
  String get passwordsDontMatch => 'पासवर्ड जुळत नाहीत';

  @override
  String payAmount(String amount) {
    return '$amount भरा';
  }

  @override
  String get perkFaster => 'जतन पत्त्यांमुळे जलद चेकआउट';

  @override
  String get perkSync => 'विशलिस्ट आणि बॅग खात्यात जतन';

  @override
  String get perkTrack => 'प्रत्येक ऑर्डर ट्रॅक करा';

  @override
  String get privacyPolicy => 'गोपनीयता धोरण';

  @override
  String get profileUpdated => 'प्रोफाइल बदलले';

  @override
  String get saveAddress => 'पत्ता जतन करा';

  @override
  String get saveChanges => 'बदल जतन करा';

  @override
  String get savedAddresses => 'जतन केलेले पत्ते';

  @override
  String get settingsCaps => 'सेटिंग्ज';

  @override
  String get shippingReturns => 'शिपिंग व डिलिव्हरी';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signOutBody => 'तुमची बॅग आणि विशलिस्ट खात्यात जतन राहतील.';

  @override
  String get signOutQ => 'साइन आउट करायचे?';

  @override
  String get signedOut => 'साइन आउट झाले';

  @override
  String get termsOfUse => 'वापराच्या अटी';

  @override
  String get themeAuto => 'आपोआप';

  @override
  String get themeDark => 'गडद';

  @override
  String get themeLight => 'फिकट';

  @override
  String get updatePassword => 'पासवर्ड बदला';

  @override
  String version(String v) {
    return 'आवृत्ती $v';
  }

  @override
  String get updateReady =>
      'निर्मल मार्टची नवीन आवृत्ती तयार आहे. वापरण्यासाठी रीस्टार्ट करा.';

  @override
  String get later => 'नंतर';

  @override
  String get restart => 'रीस्टार्ट';

  @override
  String get contactUsTitle => 'संपर्क करा';

  @override
  String get contactUsBody => 'तुमच्यासाठी जे सोपे असेल ते निवडा.';

  @override
  String get contactUsSub => 'WhatsApp, ईमेल किंवा कॉल';

  @override
  String get contactWhatsApp => 'WhatsApp वर बोला';

  @override
  String get contactWhatsAppSub => 'सर्वात जलद — फोटोही पाठवता येतात';

  @override
  String get contactCall => 'कॉल करा';

  @override
  String callFailed(String phone) {
    return 'डायलर उघडले नाही — $phone वर कॉल करा';
  }

  @override
  String get faqTitle => 'प्रश्नोत्तरे';

  @override
  String get stillQuestion => 'अजून काही प्रश्न आहे?';

  @override
  String get followUs => 'आम्हाला फॉलो करा';

  @override
  String get followUsSub => 'नवीन उत्पादने, ऑफर्स आणि व्हिडिओ';

  @override
  String get linkFailed => 'लिंक उघडली नाही';

  @override
  String get contactEmail => 'ईमेल करा';

  @override
  String emailFailed(String email) {
    return 'ईमेल अ‍ॅप सापडले नाही — $email वर लिहा';
  }

  @override
  String helpEmailSubject(String number) {
    return 'ऑर्डर $number बाबत मदत';
  }

  @override
  String get adminNoteTitle => 'स्टोअर अ‍ॅडमिन';

  @override
  String get adminNoteBody =>
      'ऑर्डर्स, उत्पादने, स्टॉक आणि सेटिंग्ज वेबसाइटवरून सांभाळल्या जातात.';

  @override
  String get adminNoteOpen => 'अ‍ॅडमिन उघडा';

  @override
  String get refundPolicy => 'परतावा व रद्द धोरण';

  @override
  String upiRef(String ref) {
    return 'UPI संदर्भ $ref';
  }

  @override
  String get forgotEmailBody =>
      'तुमच्या खात्याचा ईमेल टाका, नवीन पासवर्ड निवडण्यासाठी आम्ही लिंक पाठवू.';

  @override
  String get sendResetLink => 'रीसेट लिंक पाठवा';

  @override
  String get checkYourEmail => 'तुमचा ईमेल तपासा';

  @override
  String resetSentBody(String email) {
    return '$email चे खाते असल्यास पासवर्ड रीसेट लिंक पाठवली आहे. ती 1 तास चालते — स्पॅमही तपासा. नवीन पासवर्ड निवडल्यावर इथे साइन इन करा.';
  }

  @override
  String get backToSignIn => 'साइन इन कडे परत';

  @override
  String get resendLink => 'मिळाली नाही? पुन्हा पाठवा';

  @override
  String get forgotNoEmailAccess => 'ईमेल उघडता येत नाही? WhatsApp करा';

  @override
  String get notificationsCaps => 'नोटिफिकेशन्स';

  @override
  String get notifOrders => 'ऑर्डर अपडेट्स';

  @override
  String get notifOrdersSub => 'पेमेंट, शिपिंग, डिलिव्हरी आणि परतावा';

  @override
  String get notifOffers => 'ऑफर्स व डील्स';

  @override
  String get notifOffersSub => 'सेल आणि नवीन वस्तू';

  @override
  String get notifBlocked =>
      'निर्मल मार्टसाठी नोटिफिकेशन्स बंद आहेत. फोनच्या सेटिंग्ज → अ‍ॅप्स → Nirmal Mart → नोटिफिकेशन्स येथे चालू करा.';
}
