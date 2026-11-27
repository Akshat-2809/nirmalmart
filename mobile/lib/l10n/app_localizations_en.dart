// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nirmal Mart';

  @override
  String get tabHome => 'Home';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabWishlist => 'Wishlist';

  @override
  String get tabAccount => 'Account';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeBrowseGuest => 'Browse as guest';

  @override
  String get authSkip => 'Skip';

  @override
  String get authBack => 'Back';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSub => 'Sign in to continue shopping.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSub => 'It takes less than a minute.';

  @override
  String get tabSignIn => 'Sign in';

  @override
  String get tabCreateAccount => 'Create account';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get hintFullName => 'Your name';

  @override
  String get fieldEmailOrUsername => 'Email or username';

  @override
  String get fieldEmail => 'Email';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get fieldMobile => 'Mobile number';

  @override
  String get hintMobile => '10-digit number';

  @override
  String get fieldPassword => 'Password';

  @override
  String get hintPassword => 'Your password';

  @override
  String get hintNewPassword => 'At least 8 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newToNirmalMart => 'New to Nirmal Mart?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get termsNote =>
      'By creating an account you agree to Nirmal Mart’s Terms and Privacy Policy.';

  @override
  String get errName => 'Please enter your name using letters only';

  @override
  String get errEmail => 'Please enter a valid email';

  @override
  String get errLogin => 'Please enter your email or username';

  @override
  String get errMobile =>
      'Please enter a 10-digit mobile number starting with 6–9';

  @override
  String get errPasswordShort => 'Password must be at least 8 characters';

  @override
  String get errPasswordEmpty => 'Please enter your password';

  @override
  String signedInWelcome(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String registeredWelcome(String name) {
    return 'Welcome to Nirmal Mart, $name! 🎉';
  }

  @override
  String get strength0 => 'Too weak';

  @override
  String get strength1 => 'Weak';

  @override
  String get strength2 => 'Okay';

  @override
  String get strength3 => 'Good';

  @override
  String get strength4 => 'Strong';

  @override
  String get strengthHint => 'use 8+ characters with numbers & symbols';

  @override
  String get forgotTitle => 'Forgot your password?';

  @override
  String get forgotBody =>
      'Message us on WhatsApp from your registered mobile number and we’ll help you reset it. Reset by email is coming soon.';

  @override
  String get forgotWhatsApp => 'Message us on WhatsApp';

  @override
  String forgotWhatsAppText(String email) {
    return 'Hello Nirmal Mart, I forgot my app password. My account email is: $email';
  }

  @override
  String get whatsAppMissing => 'Couldn’t open WhatsApp';

  @override
  String get secureNote => 'Your details are safe with us';

  @override
  String get homeSearchHint => 'Search Nirmal Mart';

  @override
  String get homeDeliverTo => 'Deliver to';

  @override
  String get homeAddPincode => 'Add pincode';

  @override
  String get homeBag => 'Bag';

  @override
  String get offersLabel => 'Offers';

  @override
  String get promoTrendingBadge => 'Trending now';

  @override
  String get promoTrendingTitle => 'Trending Gadgets';

  @override
  String get promoTrendingAlt => 'ट्रेंडिंग गॅझेट्स';

  @override
  String promoUpTo(int pct) {
    return 'Up to $pct% off';
  }

  @override
  String get promoBudgetBadge => 'Budget picks';

  @override
  String get promoBudgetTitle => 'Under ₹999';

  @override
  String get promoBudgetAlt => '₹999 पेक्षा कमी किमतीत';

  @override
  String promoBudgetLine(int count) {
    return '$count great gadgets';
  }

  @override
  String get promoCategoryBadge => 'Shop by category';

  @override
  String promoFrom(String price) {
    return 'From $price';
  }

  @override
  String get shopNow => 'Shop now';

  @override
  String get dealsEndsIn => 'Ends in';

  @override
  String get seeAll => 'See all';

  @override
  String get trendingAlt => 'ट्रेंडिंग गॅझेट्स';

  @override
  String get viewAll => 'View all';

  @override
  String showMore(int count) {
    return 'Show more ($count left)';
  }

  @override
  String get recentEyebrow => 'Pick up where you left off';

  @override
  String get recentTitle => 'Recently viewed';

  @override
  String get loadingSlow => 'Loading the latest deals…';

  @override
  String get loadError => 'Couldn’t load the shop';

  @override
  String get loadErrorBody =>
      'Please check your internet connection and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get add => 'Add';

  @override
  String get addedToBag => 'Added to bag';

  @override
  String get viewBag => 'View bag';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get bestseller => 'Bestseller';

  @override
  String get savedToWishlist => 'Saved to wishlist';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String get wishlistError => 'Couldn’t update your wishlist';

  @override
  String get addToWishlist => 'Save to wishlist';

  @override
  String get removeFromWishlist => 'Remove from wishlist';

  @override
  String get pincodeTitle => 'Where should we deliver?';

  @override
  String get pincodeBody =>
      'Enter your pincode to see when your order will arrive.';

  @override
  String get pincodeField => 'Pincode';

  @override
  String get pincodeCheck => 'Check';

  @override
  String pincodeDeliveryBy(String date) {
    return 'Delivery by $date';
  }

  @override
  String get pincodeUnserviceable =>
      'Sorry, we don’t deliver to this pincode yet';

  @override
  String get pincodeInvalid => 'Please enter a valid 6-digit pincode';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeGreetingGuest => 'Hello';

  @override
  String get homeSearchFor => 'Search';

  @override
  String get catTitle => 'Shop by category';

  @override
  String get catAlt => 'विभागानुसार खरेदी';

  @override
  String get dodBadge => 'Deal of the day';

  @override
  String dodOnlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String get dodSellingFast => 'Selling fast';

  @override
  String get moreDealsTitle => 'More deals for today';

  @override
  String get moreDealsAlt => 'आजच्या ऑफर्स';

  @override
  String get budgetTitle => 'Shop by budget';

  @override
  String get budgetAlt => 'बजेटनुसार खरेदी';

  @override
  String get budgetUnder => 'Under';

  @override
  String get budgetPremium => 'Premium';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get trendingNow => 'Trending now';

  @override
  String get justForYou => 'Just for you';

  @override
  String get justForYouAlt => 'तुमच्यासाठी खास';

  @override
  String get madeWith => 'Made with ❤️ in Maharashtra';

  @override
  String youSave(String amount) {
    return 'Save $amount';
  }

  @override
  String offTag(int pct) {
    return '$pct% OFF';
  }

  @override
  String get addCaps => 'ADD';

  @override
  String get removeOne => 'Remove one';

  @override
  String get addOne => 'Add one more';

  @override
  String freeDeliveryMore(String amount) {
    return 'Add $amount more for FREE delivery';
  }

  @override
  String photoOf(int n, int total) {
    return 'Photo $n of $total';
  }

  @override
  String get close => 'Close';

  @override
  String get inclusiveTaxes => 'Inclusive of all taxes';

  @override
  String get inStock => 'In stock, ready to ship';

  @override
  String hurryOnlyLeft(int count) {
    return 'Hurry — only $count left';
  }

  @override
  String get quantity => 'Quantity';

  @override
  String get benefitDelivery => 'Free delivery\nabove ₹499';

  @override
  String get benefitReturns => '5-day return\n/ exchange';

  @override
  String get benefitSecure => 'Secure\nUPI payment';

  @override
  String get deliveryCheckTitle => 'Check delivery date';

  @override
  String get deliveryEnterPin => 'Enter your pincode';

  @override
  String get deliveryChecking => 'Checking…';

  @override
  String get deliveryGetItBy => 'Get it by';

  @override
  String deliveringTo(String pin) {
    return 'Delivering to $pin';
  }

  @override
  String get change => 'Change';

  @override
  String get aboutProduct => 'About this product';

  @override
  String get highlights => 'Highlights';

  @override
  String get specifications => 'Specifications';

  @override
  String get ratingsReviews => 'Ratings & reviews';

  @override
  String get writeReview => 'Write a review';

  @override
  String get signInToReview => 'Sign in to review';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get noReviewsBody => 'Bought this? Tell others how it is.';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get verifiedPurchase => 'Verified purchase';

  @override
  String get reviewTapStars => 'Tap the stars to rate';

  @override
  String get reviewPickStars => 'Please choose a star rating';

  @override
  String get star1 => 'Poor';

  @override
  String get star2 => 'Fair';

  @override
  String get star3 => 'Good';

  @override
  String get star4 => 'Very good';

  @override
  String get star5 => 'Excellent';

  @override
  String get reviewTitle => 'Title (optional)';

  @override
  String get reviewComment => 'Your review (optional)';

  @override
  String get postReview => 'Post review';

  @override
  String get reviewThanks => 'Thanks for your review!';

  @override
  String shareText(String name, String price, String link) {
    return '$name for just $price at Nirmal Mart 🛒\n$link';
  }

  @override
  String get share => 'Share';

  @override
  String get topDeal => 'Top deal';

  @override
  String get catTrendingChip => 'Trending';

  @override
  String get newArrival => 'New arrival';

  @override
  String get beFirstToReview => 'Be the first to review';

  @override
  String get youMayAlsoLike => 'You may also like';

  @override
  String get addToBag => 'Add to bag';

  @override
  String get goToBag => 'Go to bag';

  @override
  String get buyNow => 'Buy now';

  @override
  String get productGone => 'This product isn’t available';

  @override
  String get productGoneBody =>
      'It may have been removed from the shop. Have a look at what’s new instead.';

  @override
  String get backToShopping => 'Back to shopping';

  @override
  String get searchHint => 'Search in English or मराठी';

  @override
  String get clearSearch => 'Clear';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get popularNow => 'Popular right now';

  @override
  String get browseCategories => 'Browse categories';

  @override
  String seeAllResultsFor(String q) {
    return 'See all results for “$q”';
  }

  @override
  String get useThisName => 'Search this name';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String resultsFor(String q) {
    return 'for “$q”';
  }

  @override
  String showingResultsFor(String q, String word) {
    return 'Showing results for “$q”: $word';
  }

  @override
  String get showingSimilar => 'Showing close matches';

  @override
  String noResultsFor(String q) {
    return 'No results for “$q”';
  }

  @override
  String get noResultsBody => 'Check the spelling, or try a simpler word.';

  @override
  String get didYouMean => 'Did you mean';

  @override
  String get youMightLike => 'You might like these';

  @override
  String get noFilterResults => 'Nothing matches these filters';

  @override
  String get noFilterResultsBody => 'Try removing a filter.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterInStock => 'In stock';

  @override
  String under(String price) {
    return 'Under $price';
  }

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortBest => 'Best match';

  @override
  String get sortPriceLow => 'Price: low to high';

  @override
  String get sortPriceHigh => 'Price: high to low';

  @override
  String get sortDiscount => 'Biggest discount';

  @override
  String get sortNewest => 'Newest';

  @override
  String get shopAlt => 'खरेदी';

  @override
  String get shopEmpty => 'Nothing here yet';

  @override
  String get shopEmptyBody =>
      'New products are added often — have a look at the rest of the shop.';

  @override
  String get seeAllProducts => 'See all products';

  @override
  String productsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get backToTop => 'Back to top';

  @override
  String get sortPopular => 'Popular';

  @override
  String get filters => 'Filters';

  @override
  String get allProducts => 'All';

  @override
  String removeFilter(String name) {
    return 'Remove filter $name';
  }

  @override
  String get viewGrid => 'Grid view';

  @override
  String get viewList => 'List view';

  @override
  String get categoryLabel => 'Category';

  @override
  String get priceLabel => 'Price';

  @override
  String get brandLabel => 'Brand';

  @override
  String get inStockOnly => 'In stock only';

  @override
  String get reset => 'Reset';

  @override
  String get showResults => 'Show results';

  @override
  String get noProductsMatch => 'No products match';

  @override
  String showProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count products',
      one: 'Show 1 product',
    );
    return '$_temp0';
  }

  @override
  String get myBag => 'My bag';

  @override
  String get myBagAlt => 'माझी बॅग';

  @override
  String get freeDeliveryUnlocked => 'Yay! You get FREE delivery on this order';

  @override
  String get deliveryBy => 'by';

  @override
  String get lineSoldOut => 'Out of stock — remove it to continue';

  @override
  String lineOnlyLeft(int count) {
    return 'Only $count left — reduce the quantity';
  }

  @override
  String percentOff(int pct) {
    return '$pct% off';
  }

  @override
  String get remove => 'Remove';

  @override
  String get removedFromBag => 'Removed from bag';

  @override
  String get undo => 'Undo';

  @override
  String get moveToWishlist => 'Move to wishlist';

  @override
  String get movedToWishlist => 'Moved to wishlist';

  @override
  String get fixQuantity => 'Set to what\'s left';

  @override
  String fillGapTitle(String amount) {
    return 'Add $amount more for free delivery';
  }

  @override
  String get fillGapBody => 'Any one of these gets you there';

  @override
  String get priceDetails => 'Price details';

  @override
  String mrpItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'MRP ($count items)',
      one: 'MRP (1 item)',
    );
    return '$_temp0';
  }

  @override
  String get discount => 'Discount';

  @override
  String get deliveryLabel => 'Delivery';

  @override
  String get free => 'FREE';

  @override
  String get total => 'Total';

  @override
  String includesGst(String amount) {
    return 'Includes GST $amount';
  }

  @override
  String savingOnOrder(String amount) {
    return 'You’re saving $amount on this order';
  }

  @override
  String get secureCheckout => 'Secure checkout';

  @override
  String get payByUpi => 'Pay by UPI';

  @override
  String get fiveDayReturns => '5-day returns';

  @override
  String get fixBagFirst => 'Some items need attention before checkout';

  @override
  String get viewDetails => 'View details';

  @override
  String get checkout => 'Checkout';

  @override
  String get bagEmpty => 'Your bag is empty';

  @override
  String get bagEmptyAlt => 'तुमची बॅग रिकामी आहे';

  @override
  String get bagEmptyBody =>
      'Trending gadgets and home essentials are waiting.';

  @override
  String get startShopping => 'Start shopping';

  @override
  String inYourWishlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in your wishlist',
      one: '1 item in your wishlist',
    );
    return '$_temp0';
  }

  @override
  String get view => 'View';

  @override
  String get checkoutAlt => 'चेकआउट';

  @override
  String get deliverToCaps => 'DELIVER TO';

  @override
  String itemsCaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ITEMS',
      one: '1 ITEM',
    );
    return '$_temp0';
  }

  @override
  String get editBag => 'Edit bag';

  @override
  String get deliveryInstructions => 'Delivery instructions (optional)';

  @override
  String get paymentCaps => 'PAYMENT';

  @override
  String get upiApps => 'Google Pay, PhonePe, Paytm, BHIM…';

  @override
  String get payAfterPlacing =>
      'You’ll pay right after placing the order — open your UPI app from here, or scan the QR.';

  @override
  String itemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Items ($count)',
      one: 'Items (1)',
    );
    return '$_temp0';
  }

  @override
  String get youSavedLabel => 'You save';

  @override
  String get toPay => 'To pay';

  @override
  String placeOrder(String amount) {
    return 'Place order · $amount';
  }

  @override
  String get placingOrder => 'Placing order…';

  @override
  String get agreeTerms =>
      'By placing the order you agree to the Terms & Privacy Policy';

  @override
  String get orderFailed => 'Couldn’t place the order. Please try again.';

  @override
  String get addAddressFirst => 'Add a delivery address to continue';

  @override
  String get addressesError => 'Couldn’t load your addresses';

  @override
  String get addDeliveryAddress => 'Add delivery address';

  @override
  String get chooseAddress => 'Deliver to';

  @override
  String get addNewAddress => 'Add new address';

  @override
  String get newAddress => 'New address';

  @override
  String get fieldLine1 => 'House no., building, street';

  @override
  String get fieldLine2 => 'Area, landmark (optional)';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldState => 'State';

  @override
  String get errLine1 => 'Enter house no. and street';

  @override
  String get errCity => 'Enter a city name using letters only';

  @override
  String get errState => 'Select state';

  @override
  String get labelHome => 'Home';

  @override
  String get labelWork => 'Work';

  @override
  String get labelOther => 'Other';

  @override
  String get saveDeliverHere => 'Save and deliver here';

  @override
  String get orderPlaced => 'Order placed!';

  @override
  String get orderPlacedPay =>
      'One last step — pay by UPI and send us the proof.';

  @override
  String get orderPlacedThanks =>
      'Thank you for shopping with Nirmal Mart. We’ll keep you posted.';

  @override
  String orderNumber(String number) {
    return 'Order $number';
  }

  @override
  String get orderIdCopied => 'Order ID copied';

  @override
  String get viewOrder => 'View order';

  @override
  String get continueShopping => 'Continue shopping';

  @override
  String get paymentPending => 'Payment pending';

  @override
  String payByUpi2(String amount) {
    return 'Pay $amount by UPI';
  }

  @override
  String qrFor(String payee) {
    return 'UPI QR code for $payee';
  }

  @override
  String get payWithUpiApp => 'Pay with UPI app';

  @override
  String get saveQr => 'Save QR to gallery';

  @override
  String get copyUpiId => 'Copy UPI ID';

  @override
  String get upiIdCopied => 'UPI ID copied';

  @override
  String get noUpiApp => 'No UPI app found — scan or save the QR instead';

  @override
  String get qrSaved => 'QR saved to your gallery — open it from your UPI app';

  @override
  String get qrNotSaved => 'Couldn’t save the QR — please allow photo access';

  @override
  String get payStepsTitle => 'How to pay';

  @override
  String payStep1(String amount) {
    return 'Pay exactly $amount — tap Pay with UPI app, or scan the QR.';
  }

  @override
  String get payStep2 => 'Take a screenshot of the successful payment.';

  @override
  String get payStep3 =>
      'Tap the green button and attach the screenshot in WhatsApp.';

  @override
  String get utrHint => 'UPI reference / UTR no. (optional)';

  @override
  String get sendProof => 'Send payment proof on WhatsApp';

  @override
  String sendProofNote(String number) {
    return 'Sends to $number. We’ll confirm your order once the payment is checked.';
  }

  @override
  String get beingPacked => 'Being packed';

  @override
  String get buyAgain => 'Buy again';

  @override
  String get buyAgainNone => 'These items are sold out right now';

  @override
  String buyAgainSome(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added — the rest are sold out',
      one: '1 item added — the rest are sold out',
    );
    return '$_temp0';
  }

  @override
  String get cancelExchangeQ => 'Cancel this exchange?';

  @override
  String get cancelReturnQ => 'Cancel this return?';

  @override
  String get cancelRequestBody => 'The courier pickup will be called off too.';

  @override
  String get cancelNoChargeNote =>
      'No payment has been confirmed for this order, so nothing will be charged.';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelPackedNote =>
      'Your parcel is packed. Cancelling now also cancels the courier pickup.';

  @override
  String cancelRefundNote(String amount) {
    return 'Your $amount will be refunded to the UPI account you paid from.';
  }

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelledNothingCharged => 'Cancelled · nothing was charged';

  @override
  String cancelledOn(String date) {
    return 'Cancelled on $date';
  }

  @override
  String cancelledRefundPending(String amount) {
    return 'Cancelled · $amount refund on the way';
  }

  @override
  String cancelledRefunded(String amount) {
    return 'Cancelled · $amount refunded';
  }

  @override
  String deliveredOn(String date) {
    return 'Delivered $date';
  }

  @override
  String deliveredReturnUntil(String date, String until) {
    return 'Delivered $date · return until $until';
  }

  @override
  String get deliveringToCaps => 'DELIVERING TO';

  @override
  String get details => 'Details';

  @override
  String get exchangeIt => 'Exchange';

  @override
  String get exchangeNote =>
      'We’ll pick up the item and send you a replacement — no extra charge.';

  @override
  String get exchangeRequested => 'Exchange requested — we’ll be in touch';

  @override
  String get exchangeWord => 'Exchange';

  @override
  String helpMessage(String number) {
    return 'Hello Nirmal Mart, I need help with my order $number.';
  }

  @override
  String inReturn(int count) {
    return '$count in return';
  }

  @override
  String get keepIt => 'Keep it';

  @override
  String get keepOrder => 'Keep order';

  @override
  String get myOrders => 'My orders';

  @override
  String get myOrdersAlt => 'माझ्या ऑर्डर्स';

  @override
  String get needHelp => 'Need help?';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get noOrdersBody => 'When you order something, you’ll find it here.';

  @override
  String get noOrdersHere => 'Nothing here';

  @override
  String get onTheWay => 'On the way';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get orderConfirmedLine => 'Order confirmed · we’ll pack it soon';

  @override
  String get orderDetails => 'Order details';

  @override
  String get ordersActive => 'Active';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String paidBy(String method) {
    return 'Payment: $method';
  }

  @override
  String get payNow => 'Pay now';

  @override
  String payToConfirm(String amount) {
    return 'Pay $amount to confirm your order';
  }

  @override
  String get payToConfirmBody =>
      'We’ll start packing once your UPI payment is checked.';

  @override
  String get pickItemsAndReason => 'Choose the items and a reason';

  @override
  String get pickReason => 'Choose a reason';

  @override
  String placedOn(String when) {
    return 'Placed $when';
  }

  @override
  String plusMore(int count) {
    return '+$count more';
  }

  @override
  String qtyPrice(int qty, String price) {
    return 'Qty $qty · $price';
  }

  @override
  String get rateItems => 'Rate items';

  @override
  String refundDone(String amount) {
    return '$amount refunded to your UPI account';
  }

  @override
  String refundOnTheWay(String amount) {
    return '$amount refund on the way to your UPI account';
  }

  @override
  String refundToUpi(String amount) {
    return 'refund $amount to your UPI';
  }

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get requestExchange => 'Request exchange';

  @override
  String get requestReturn => 'Request return';

  @override
  String get retApproved => 'Approved';

  @override
  String get retExchanged => 'Exchanged';

  @override
  String get retPickedUp => 'Picked up';

  @override
  String get retPickupScheduled => 'Pickup scheduled';

  @override
  String get retReceived => 'Received';

  @override
  String get retRefunded => 'Refunded';

  @override
  String get retRejected => 'Not approved';

  @override
  String get retRequested => 'Requested';

  @override
  String get returnCommentHint => 'Anything else we should know? (optional)';

  @override
  String get returnExchange => 'Return / exchange';

  @override
  String get returnForRefund => 'Return';

  @override
  String get returnInProgressLine => 'Return or exchange in progress';

  @override
  String returnNote(String amount) {
    return 'We’ll pick it up from your address. $amount will be refunded to your UPI once it reaches us.';
  }

  @override
  String get returnNoteNoAmount =>
      'We’ll pick it up from your address and refund you once it reaches us.';

  @override
  String get returnRequested => 'Return requested — we’ll be in touch';

  @override
  String returnUntilDays(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Return or exchange until $date · $days days left',
      one: 'Return or exchange until $date · 1 day left',
    );
    return '$_temp0';
  }

  @override
  String returnUntilToday(String date) {
    return 'Return or exchange until $date · last day';
  }

  @override
  String get returnWord => 'Return';

  @override
  String get sendProofShort => 'Send proof';

  @override
  String get stAwaitingPayment => 'Awaiting payment';

  @override
  String get stCancelled => 'Cancelled';

  @override
  String get stConfirmed => 'Confirmed';

  @override
  String get stDelivered => 'Delivered';

  @override
  String get stPacked => 'Packed';

  @override
  String get stRefundPending => 'Refund pending';

  @override
  String get stRefunded => 'Refunded';

  @override
  String get stReturnInProgress => 'Return in progress';

  @override
  String get stShipped => 'Shipped';

  @override
  String get statusCaps => 'STATUS';

  @override
  String get stepConfirmed => 'Confirmed';

  @override
  String get stepDelivered => 'Delivered';

  @override
  String get stepPacked => 'Packed';

  @override
  String get stepPlaced => 'Placed';

  @override
  String get stepShipped => 'Shipped';

  @override
  String get today => 'Today';

  @override
  String get track => 'Track';

  @override
  String get trackPickup => 'Track pickup';

  @override
  String get upiPending => 'UPI (pending)';

  @override
  String get whatsWrong => 'What’s the reason?';

  @override
  String get whichItems => 'Which items?';

  @override
  String get whyCancel => 'Why are you cancelling?';

  @override
  String addedToBagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to bag',
      one: '1 item added to bag',
    );
    return '$_temp0';
  }

  @override
  String get wishlistShareTitle => 'My Nirmal Mart wishlist 🛒';

  @override
  String get wishlistGuest =>
      'Saved on this phone only. Sign in to keep it on every device.';

  @override
  String priceDropBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are cheaper than when you saved them',
      one: '1 item is cheaper than when you saved it',
    );
    return '$_temp0';
  }

  @override
  String get wishlistAlt => 'विशलिस्ट';

  @override
  String savedCount(int count) {
    return '$count saved';
  }

  @override
  String get addAllToBag => 'Add all to bag';

  @override
  String get movedToBag => 'Moved to bag';

  @override
  String get inYourBag => 'In your bag';

  @override
  String get moveToBag => 'Move to bag';

  @override
  String priceDropped(String amount) {
    return 'Price dropped $amount';
  }

  @override
  String get wishlistEmpty => 'Nothing saved yet';

  @override
  String get wishlistEmptyBody =>
      'Tap the ♡ on any product to save it here for later.';

  @override
  String get exploreProducts => 'Explore products';

  @override
  String get accountCaps => 'ACCOUNT';

  @override
  String get accountDeleted => 'Your account has been deleted';

  @override
  String get accountGuestBody =>
      'Sign in to track orders and keep your bag and wishlist on every device.';

  @override
  String get accountHello => 'Hello!';

  @override
  String get addressDeleted => 'Address removed';

  @override
  String get addressesTile => 'Addresses';

  @override
  String get appearance => 'Appearance';

  @override
  String awaitingPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count awaiting payment',
      one: '1 awaiting payment',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get changePassword => 'Change password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get defaultSet => 'Default address updated';

  @override
  String get defaultTag => 'DEFAULT';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountQ => 'Delete your account?';

  @override
  String get deleteAccountSub => 'Permanently remove your account';

  @override
  String get deleteAddressQ => 'Remove this address?';

  @override
  String get deleteEnterPassword => 'Enter your password to confirm';

  @override
  String get deleteKeepsOrders =>
      'Order records are kept without your contact details, as required for GST and returns. Orders still on their way must be delivered or cancelled first.';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deletePoint1 =>
      'Your name, email, mobile, saved addresses, bag and wishlist are erased.';

  @override
  String get deletePoint2 =>
      'You’ll be signed out and can’t sign in to this account again.';

  @override
  String get deletePoint3 =>
      'This can’t be undone. You can create a new account later with the same email.';

  @override
  String get edit => 'Edit';

  @override
  String get editAddress => 'Edit address';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get emailCantChange => 'Email can’t be changed';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get faqs => 'FAQs';

  @override
  String get helpCaps => 'HELP';

  @override
  String get helpGeneral => 'Hello Nirmal Mart, I have a question.';

  @override
  String get keepMyAccount => 'Keep my account';

  @override
  String get language => 'Language';

  @override
  String get makeDefault => 'Make default';

  @override
  String get myStuffCaps => 'MY STUFF';

  @override
  String get newPassword => 'New password';

  @override
  String get noAddressesBody => 'Add one now and checkout will be quicker.';

  @override
  String get noAddressesYet => 'No saved addresses';

  @override
  String get ordersTile => 'Orders';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get passwordsDontMatch => 'Passwords don’t match';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get perkFaster => 'Faster checkout with saved addresses';

  @override
  String get perkSync => 'Wishlist and bag saved to your account';

  @override
  String get perkTrack => 'Track every order';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get saveAddress => 'Save address';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get settingsCaps => 'SETTINGS';

  @override
  String get shippingReturns => 'Shipping & delivery';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutBody => 'Your bag and wishlist stay saved in your account.';

  @override
  String get signOutQ => 'Sign out?';

  @override
  String get signedOut => 'Signed out';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get updatePassword => 'Update password';

  @override
  String version(String v) {
    return 'version $v';
  }

  @override
  String get updateReady =>
      'A new version of Nirmal Mart is ready. Restart to use it.';

  @override
  String get later => 'Later';

  @override
  String get restart => 'Restart';

  @override
  String get contactUsTitle => 'Contact us';

  @override
  String get contactUsBody => 'Choose whichever is easier for you.';

  @override
  String get contactUsSub => 'WhatsApp, email or call';

  @override
  String get contactWhatsApp => 'Chat on WhatsApp';

  @override
  String get contactWhatsAppSub => 'Quickest — send photos too';

  @override
  String get contactCall => 'Call us';

  @override
  String callFailed(String phone) {
    return 'Couldn’t open the dialer — call $phone';
  }

  @override
  String get faqTitle => 'FAQs';

  @override
  String get stillQuestion => 'Still have a question?';

  @override
  String get followUs => 'Follow us';

  @override
  String get followUsSub => 'New arrivals, offers and product videos';

  @override
  String get linkFailed => 'Couldn’t open the link';

  @override
  String get contactEmail => 'Email us';

  @override
  String emailFailed(String email) {
    return 'No email app found — write to $email';
  }

  @override
  String helpEmailSubject(String number) {
    return 'Help with order $number';
  }

  @override
  String get adminNoteTitle => 'Store admin';

  @override
  String get adminNoteBody =>
      'Orders, products, stock and settings are managed on the website.';

  @override
  String get adminNoteOpen => 'Open admin';

  @override
  String get refundPolicy => 'Refund & cancellation policy';

  @override
  String upiRef(String ref) {
    return 'UPI ref $ref';
  }

  @override
  String get forgotEmailBody =>
      'Enter your account email and we’ll send you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String resetSentBody(String email) {
    return 'If $email has an account, we’ve sent a link to reset the password. It works for 1 hour — check spam too. After choosing a new password, sign in here.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resendLink => 'Didn’t get it? Send again';

  @override
  String get forgotNoEmailAccess => 'Can’t get into your email? WhatsApp us';

  @override
  String get notificationsCaps => 'NOTIFICATIONS';

  @override
  String get notifOrders => 'Order updates';

  @override
  String get notifOrdersSub => 'Payment, shipping, delivery and refunds';

  @override
  String get notifOffers => 'Offers & deals';

  @override
  String get notifOffersSub => 'Sales and new arrivals';

  @override
  String get notifBlocked =>
      'Notifications are off for Nirmal Mart. Turn them on in your phone’s Settings → Apps → Nirmal Mart → Notifications.';
}
