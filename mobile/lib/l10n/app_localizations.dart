import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nirmal Mart'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get tabWishlist;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeBrowseGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as guest'**
  String get welcomeBrowseGuest;

  /// No description provided for @authSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get authSkip;

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue shopping.'**
  String get loginSub;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSub.
  ///
  /// In en, this message translates to:
  /// **'It takes less than a minute.'**
  String get registerSub;

  /// No description provided for @tabSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get tabSignIn;

  /// No description provided for @tabCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get tabCreateAccount;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @hintFullName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get hintFullName;

  /// No description provided for @fieldEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get fieldEmailOrUsername;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get hintEmail;

  /// No description provided for @fieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get fieldMobile;

  /// No description provided for @hintMobile.
  ///
  /// In en, this message translates to:
  /// **'10-digit number'**
  String get hintMobile;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get hintPassword;

  /// No description provided for @hintNewPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get hintNewPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newToNirmalMart.
  ///
  /// In en, this message translates to:
  /// **'New to Nirmal Mart?'**
  String get newToNirmalMart;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @termsNote.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to Nirmal Mart’s Terms and Privacy Policy.'**
  String get termsNote;

  /// No description provided for @errName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name using letters only'**
  String get errName;

  /// No description provided for @errEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get errEmail;

  /// No description provided for @errLogin.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or username'**
  String get errLogin;

  /// No description provided for @errMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 10-digit mobile number starting with 6–9'**
  String get errMobile;

  /// No description provided for @errPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get errPasswordShort;

  /// No description provided for @errPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get errPasswordEmpty;

  /// No description provided for @signedInWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String signedInWelcome(String name);

  /// No description provided for @registeredWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nirmal Mart, {name}! 🎉'**
  String registeredWelcome(String name);

  /// No description provided for @strength0.
  ///
  /// In en, this message translates to:
  /// **'Too weak'**
  String get strength0;

  /// No description provided for @strength1.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strength1;

  /// No description provided for @strength2.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get strength2;

  /// No description provided for @strength3.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strength3;

  /// No description provided for @strength4.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strength4;

  /// No description provided for @strengthHint.
  ///
  /// In en, this message translates to:
  /// **'use 8+ characters with numbers & symbols'**
  String get strengthHint;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Message us on WhatsApp from your registered mobile number and we’ll help you reset it. Reset by email is coming soon.'**
  String get forgotBody;

  /// No description provided for @forgotWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message us on WhatsApp'**
  String get forgotWhatsApp;

  /// No description provided for @forgotWhatsAppText.
  ///
  /// In en, this message translates to:
  /// **'Hello Nirmal Mart, I forgot my app password. My account email is: {email}'**
  String forgotWhatsAppText(String email);

  /// No description provided for @whatsAppMissing.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open WhatsApp'**
  String get whatsAppMissing;

  /// No description provided for @secureNote.
  ///
  /// In en, this message translates to:
  /// **'Your details are safe with us'**
  String get secureNote;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Nirmal Mart'**
  String get homeSearchHint;

  /// No description provided for @homeDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get homeDeliverTo;

  /// No description provided for @homeAddPincode.
  ///
  /// In en, this message translates to:
  /// **'Add pincode'**
  String get homeAddPincode;

  /// No description provided for @homeBag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get homeBag;

  /// No description provided for @offersLabel.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersLabel;

  /// No description provided for @promoTrendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get promoTrendingBadge;

  /// No description provided for @promoTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending Gadgets'**
  String get promoTrendingTitle;

  /// No description provided for @promoTrendingAlt.
  ///
  /// In en, this message translates to:
  /// **'ट्रेंडिंग गॅझेट्स'**
  String get promoTrendingAlt;

  /// No description provided for @promoUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {pct}% off'**
  String promoUpTo(int pct);

  /// No description provided for @promoBudgetBadge.
  ///
  /// In en, this message translates to:
  /// **'Budget picks'**
  String get promoBudgetBadge;

  /// No description provided for @promoBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Under ₹999'**
  String get promoBudgetTitle;

  /// No description provided for @promoBudgetAlt.
  ///
  /// In en, this message translates to:
  /// **'₹999 पेक्षा कमी किमतीत'**
  String get promoBudgetAlt;

  /// No description provided for @promoBudgetLine.
  ///
  /// In en, this message translates to:
  /// **'{count} great gadgets'**
  String promoBudgetLine(int count);

  /// No description provided for @promoCategoryBadge.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get promoCategoryBadge;

  /// No description provided for @promoFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String promoFrom(String price);

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop now'**
  String get shopNow;

  /// No description provided for @dealsEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in'**
  String get dealsEndsIn;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @trendingAlt.
  ///
  /// In en, this message translates to:
  /// **'ट्रेंडिंग गॅझेट्स'**
  String get trendingAlt;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more ({count} left)'**
  String showMore(int count);

  /// No description provided for @recentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get recentEyebrow;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentTitle;

  /// No description provided for @loadingSlow.
  ///
  /// In en, this message translates to:
  /// **'Loading the latest deals…'**
  String get loadingSlow;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the shop'**
  String get loadError;

  /// No description provided for @loadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get loadErrorBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addedToBag.
  ///
  /// In en, this message translates to:
  /// **'Added to bag'**
  String get addedToBag;

  /// No description provided for @viewBag.
  ///
  /// In en, this message translates to:
  /// **'View bag'**
  String get viewBag;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @bestseller.
  ///
  /// In en, this message translates to:
  /// **'Bestseller'**
  String get bestseller;

  /// No description provided for @savedToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Saved to wishlist'**
  String get savedToWishlist;

  /// No description provided for @removedFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// No description provided for @wishlistError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update your wishlist'**
  String get wishlistError;

  /// No description provided for @addToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Save to wishlist'**
  String get addToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get removeFromWishlist;

  /// No description provided for @pincodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we deliver?'**
  String get pincodeTitle;

  /// No description provided for @pincodeBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your pincode to see when your order will arrive.'**
  String get pincodeBody;

  /// No description provided for @pincodeField.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincodeField;

  /// No description provided for @pincodeCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get pincodeCheck;

  /// No description provided for @pincodeDeliveryBy.
  ///
  /// In en, this message translates to:
  /// **'Delivery by {date}'**
  String pincodeDeliveryBy(String date);

  /// No description provided for @pincodeUnserviceable.
  ///
  /// In en, this message translates to:
  /// **'Sorry, we don’t deliver to this pincode yet'**
  String get pincodeUnserviceable;

  /// No description provided for @pincodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit pincode'**
  String get pincodeInvalid;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingGuest.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreetingGuest;

  /// No description provided for @homeSearchFor.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchFor;

  /// No description provided for @catTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get catTitle;

  /// No description provided for @catAlt.
  ///
  /// In en, this message translates to:
  /// **'विभागानुसार खरेदी'**
  String get catAlt;

  /// No description provided for @dodBadge.
  ///
  /// In en, this message translates to:
  /// **'Deal of the day'**
  String get dodBadge;

  /// No description provided for @dodOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String dodOnlyLeft(int count);

  /// No description provided for @dodSellingFast.
  ///
  /// In en, this message translates to:
  /// **'Selling fast'**
  String get dodSellingFast;

  /// No description provided for @moreDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'More deals for today'**
  String get moreDealsTitle;

  /// No description provided for @moreDealsAlt.
  ///
  /// In en, this message translates to:
  /// **'आजच्या ऑफर्स'**
  String get moreDealsAlt;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop by budget'**
  String get budgetTitle;

  /// No description provided for @budgetAlt.
  ///
  /// In en, this message translates to:
  /// **'बजेटनुसार खरेदी'**
  String get budgetAlt;

  /// No description provided for @budgetUnder.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get budgetUnder;

  /// No description provided for @budgetPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get budgetPremium;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get trendingNow;

  /// No description provided for @justForYou.
  ///
  /// In en, this message translates to:
  /// **'Just for you'**
  String get justForYou;

  /// No description provided for @justForYouAlt.
  ///
  /// In en, this message translates to:
  /// **'तुमच्यासाठी खास'**
  String get justForYouAlt;

  /// No description provided for @madeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ in Maharashtra'**
  String get madeWith;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String youSave(String amount);

  /// No description provided for @offTag.
  ///
  /// In en, this message translates to:
  /// **'{pct}% OFF'**
  String offTag(int pct);

  /// No description provided for @addCaps.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addCaps;

  /// No description provided for @removeOne.
  ///
  /// In en, this message translates to:
  /// **'Remove one'**
  String get removeOne;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'Add one more'**
  String get addOne;

  /// No description provided for @freeDeliveryMore.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more for FREE delivery'**
  String freeDeliveryMore(String amount);

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo {n} of {total}'**
  String photoOf(int n, int total);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @inclusiveTaxes.
  ///
  /// In en, this message translates to:
  /// **'Inclusive of all taxes'**
  String get inclusiveTaxes;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock, ready to ship'**
  String get inStock;

  /// No description provided for @hurryOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Hurry — only {count} left'**
  String hurryOnlyLeft(int count);

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @benefitDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free delivery\nabove ₹499'**
  String get benefitDelivery;

  /// No description provided for @benefitReturns.
  ///
  /// In en, this message translates to:
  /// **'5-day return\n/ exchange'**
  String get benefitReturns;

  /// No description provided for @benefitSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure\nUPI payment'**
  String get benefitSecure;

  /// No description provided for @deliveryCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check delivery date'**
  String get deliveryCheckTitle;

  /// No description provided for @deliveryEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your pincode'**
  String get deliveryEnterPin;

  /// No description provided for @deliveryChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get deliveryChecking;

  /// No description provided for @deliveryGetItBy.
  ///
  /// In en, this message translates to:
  /// **'Get it by'**
  String get deliveryGetItBy;

  /// No description provided for @deliveringTo.
  ///
  /// In en, this message translates to:
  /// **'Delivering to {pin}'**
  String deliveringTo(String pin);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @aboutProduct.
  ///
  /// In en, this message translates to:
  /// **'About this product'**
  String get aboutProduct;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @ratingsReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & reviews'**
  String get ratingsReviews;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @signInToReview.
  ///
  /// In en, this message translates to:
  /// **'Sign in to review'**
  String get signInToReview;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @noReviewsBody.
  ///
  /// In en, this message translates to:
  /// **'Bought this? Tell others how it is.'**
  String get noReviewsBody;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @verifiedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Verified purchase'**
  String get verifiedPurchase;

  /// No description provided for @reviewTapStars.
  ///
  /// In en, this message translates to:
  /// **'Tap the stars to rate'**
  String get reviewTapStars;

  /// No description provided for @reviewPickStars.
  ///
  /// In en, this message translates to:
  /// **'Please choose a star rating'**
  String get reviewPickStars;

  /// No description provided for @star1.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get star1;

  /// No description provided for @star2.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get star2;

  /// No description provided for @star3.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get star3;

  /// No description provided for @star4.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get star4;

  /// No description provided for @star5.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get star5;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get reviewTitle;

  /// No description provided for @reviewComment.
  ///
  /// In en, this message translates to:
  /// **'Your review (optional)'**
  String get reviewComment;

  /// No description provided for @postReview.
  ///
  /// In en, this message translates to:
  /// **'Post review'**
  String get postReview;

  /// No description provided for @reviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get reviewThanks;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'{name} for just {price} at Nirmal Mart 🛒\n{link}'**
  String shareText(String name, String price, String link);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @topDeal.
  ///
  /// In en, this message translates to:
  /// **'Top deal'**
  String get topDeal;

  /// No description provided for @catTrendingChip.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get catTrendingChip;

  /// No description provided for @newArrival.
  ///
  /// In en, this message translates to:
  /// **'New arrival'**
  String get newArrival;

  /// No description provided for @beFirstToReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review'**
  String get beFirstToReview;

  /// No description provided for @youMayAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You may also like'**
  String get youMayAlsoLike;

  /// No description provided for @addToBag.
  ///
  /// In en, this message translates to:
  /// **'Add to bag'**
  String get addToBag;

  /// No description provided for @goToBag.
  ///
  /// In en, this message translates to:
  /// **'Go to bag'**
  String get goToBag;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @productGone.
  ///
  /// In en, this message translates to:
  /// **'This product isn’t available'**
  String get productGone;

  /// No description provided for @productGoneBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed from the shop. Have a look at what’s new instead.'**
  String get productGoneBody;

  /// No description provided for @backToShopping.
  ///
  /// In en, this message translates to:
  /// **'Back to shopping'**
  String get backToShopping;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in English or मराठी'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @popularNow.
  ///
  /// In en, this message translates to:
  /// **'Popular right now'**
  String get popularNow;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get browseCategories;

  /// No description provided for @seeAllResultsFor.
  ///
  /// In en, this message translates to:
  /// **'See all results for “{q}”'**
  String seeAllResultsFor(String q);

  /// No description provided for @useThisName.
  ///
  /// In en, this message translates to:
  /// **'Search this name'**
  String get useThisName;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'for “{q}”'**
  String resultsFor(String q);

  /// No description provided for @showingResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Showing results for “{q}”: {word}'**
  String showingResultsFor(String q, String word);

  /// No description provided for @showingSimilar.
  ///
  /// In en, this message translates to:
  /// **'Showing close matches'**
  String get showingSimilar;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for “{q}”'**
  String noResultsFor(String q);

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try a simpler word.'**
  String get noResultsBody;

  /// No description provided for @didYouMean.
  ///
  /// In en, this message translates to:
  /// **'Did you mean'**
  String get didYouMean;

  /// No description provided for @youMightLike.
  ///
  /// In en, this message translates to:
  /// **'You might like these'**
  String get youMightLike;

  /// No description provided for @noFilterResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters'**
  String get noFilterResults;

  /// No description provided for @noFilterResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter.'**
  String get noFilterResultsBody;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filterInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get filterInStock;

  /// No description provided for @under.
  ///
  /// In en, this message translates to:
  /// **'Under {price}'**
  String under(String price);

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortBest.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get sortBest;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @sortDiscount.
  ///
  /// In en, this message translates to:
  /// **'Biggest discount'**
  String get sortDiscount;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @shopAlt.
  ///
  /// In en, this message translates to:
  /// **'खरेदी'**
  String get shopAlt;

  /// No description provided for @shopEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get shopEmpty;

  /// No description provided for @shopEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New products are added often — have a look at the rest of the shop.'**
  String get shopEmptyBody;

  /// No description provided for @seeAllProducts.
  ///
  /// In en, this message translates to:
  /// **'See all products'**
  String get seeAllProducts;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String productsCount(int count);

  /// No description provided for @backToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get backToTop;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allProducts;

  /// No description provided for @removeFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove filter {name}'**
  String removeFilter(String name);

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewList;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock only'**
  String get inStockOnly;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @noProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match'**
  String get noProductsMatch;

  /// No description provided for @showProducts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 product} other{Show {count} products}}'**
  String showProducts(int count);

  /// No description provided for @myBag.
  ///
  /// In en, this message translates to:
  /// **'My bag'**
  String get myBag;

  /// No description provided for @myBagAlt.
  ///
  /// In en, this message translates to:
  /// **'माझी बॅग'**
  String get myBagAlt;

  /// No description provided for @freeDeliveryUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Yay! You get FREE delivery on this order'**
  String get freeDeliveryUnlocked;

  /// No description provided for @deliveryBy.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get deliveryBy;

  /// No description provided for @lineSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock — remove it to continue'**
  String get lineSoldOut;

  /// No description provided for @lineOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left — reduce the quantity'**
  String lineOnlyLeft(int count);

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'{pct}% off'**
  String percentOff(int pct);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removedFromBag.
  ///
  /// In en, this message translates to:
  /// **'Removed from bag'**
  String get removedFromBag;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @moveToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Move to wishlist'**
  String get moveToWishlist;

  /// No description provided for @movedToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Moved to wishlist'**
  String get movedToWishlist;

  /// No description provided for @fixQuantity.
  ///
  /// In en, this message translates to:
  /// **'Set to what\'s left'**
  String get fixQuantity;

  /// No description provided for @fillGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more for free delivery'**
  String fillGapTitle(String amount);

  /// No description provided for @fillGapBody.
  ///
  /// In en, this message translates to:
  /// **'Any one of these gets you there'**
  String get fillGapBody;

  /// No description provided for @priceDetails.
  ///
  /// In en, this message translates to:
  /// **'Price details'**
  String get priceDetails;

  /// No description provided for @mrpItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{MRP (1 item)} other{MRP ({count} items)}}'**
  String mrpItems(int count);

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @deliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryLabel;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @includesGst.
  ///
  /// In en, this message translates to:
  /// **'Includes GST {amount}'**
  String includesGst(String amount);

  /// No description provided for @savingOnOrder.
  ///
  /// In en, this message translates to:
  /// **'You’re saving {amount} on this order'**
  String savingOnOrder(String amount);

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get secureCheckout;

  /// No description provided for @payByUpi.
  ///
  /// In en, this message translates to:
  /// **'Pay by UPI'**
  String get payByUpi;

  /// No description provided for @fiveDayReturns.
  ///
  /// In en, this message translates to:
  /// **'5-day returns'**
  String get fiveDayReturns;

  /// No description provided for @fixBagFirst.
  ///
  /// In en, this message translates to:
  /// **'Some items need attention before checkout'**
  String get fixBagFirst;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @bagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get bagEmpty;

  /// No description provided for @bagEmptyAlt.
  ///
  /// In en, this message translates to:
  /// **'तुमची बॅग रिकामी आहे'**
  String get bagEmptyAlt;

  /// No description provided for @bagEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Trending gadgets and home essentials are waiting.'**
  String get bagEmptyBody;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start shopping'**
  String get startShopping;

  /// No description provided for @inYourWishlist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in your wishlist} other{{count} items in your wishlist}}'**
  String inYourWishlist(int count);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @checkoutAlt.
  ///
  /// In en, this message translates to:
  /// **'चेकआउट'**
  String get checkoutAlt;

  /// No description provided for @deliverToCaps.
  ///
  /// In en, this message translates to:
  /// **'DELIVER TO'**
  String get deliverToCaps;

  /// No description provided for @itemsCaps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ITEM} other{{count} ITEMS}}'**
  String itemsCaps(int count);

  /// No description provided for @editBag.
  ///
  /// In en, this message translates to:
  /// **'Edit bag'**
  String get editBag;

  /// No description provided for @deliveryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Delivery instructions (optional)'**
  String get deliveryInstructions;

  /// No description provided for @paymentCaps.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get paymentCaps;

  /// No description provided for @upiApps.
  ///
  /// In en, this message translates to:
  /// **'Google Pay, PhonePe, Paytm, BHIM…'**
  String get upiApps;

  /// No description provided for @payAfterPlacing.
  ///
  /// In en, this message translates to:
  /// **'You’ll pay right after placing the order — open your UPI app from here, or scan the QR.'**
  String get payAfterPlacing;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Items (1)} other{Items ({count})}}'**
  String itemsLabel(int count);

  /// No description provided for @youSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get youSavedLabel;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order · {amount}'**
  String placeOrder(String amount);

  /// No description provided for @placingOrder.
  ///
  /// In en, this message translates to:
  /// **'Placing order…'**
  String get placingOrder;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By placing the order you agree to the Terms & Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t place the order. Please try again.'**
  String get orderFailed;

  /// No description provided for @addAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address to continue'**
  String get addAddressFirst;

  /// No description provided for @addressesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your addresses'**
  String get addressesError;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add delivery address'**
  String get addDeliveryAddress;

  /// No description provided for @chooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get chooseAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get addNewAddress;

  /// No description provided for @newAddress.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get newAddress;

  /// No description provided for @fieldLine1.
  ///
  /// In en, this message translates to:
  /// **'House no., building, street'**
  String get fieldLine1;

  /// No description provided for @fieldLine2.
  ///
  /// In en, this message translates to:
  /// **'Area, landmark (optional)'**
  String get fieldLine2;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @fieldState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get fieldState;

  /// No description provided for @errLine1.
  ///
  /// In en, this message translates to:
  /// **'Enter house no. and street'**
  String get errLine1;

  /// No description provided for @errCity.
  ///
  /// In en, this message translates to:
  /// **'Enter a city name using letters only'**
  String get errCity;

  /// No description provided for @errState.
  ///
  /// In en, this message translates to:
  /// **'Select state'**
  String get errState;

  /// No description provided for @labelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get labelHome;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get labelWork;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @saveDeliverHere.
  ///
  /// In en, this message translates to:
  /// **'Save and deliver here'**
  String get saveDeliverHere;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlaced;

  /// No description provided for @orderPlacedPay.
  ///
  /// In en, this message translates to:
  /// **'One last step — pay by UPI and send us the proof.'**
  String get orderPlacedPay;

  /// No description provided for @orderPlacedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping with Nirmal Mart. We’ll keep you posted.'**
  String get orderPlacedThanks;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String orderNumber(String number);

  /// No description provided for @orderIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Order ID copied'**
  String get orderIdCopied;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get viewOrder;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @payByUpi2.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} by UPI'**
  String payByUpi2(String amount);

  /// No description provided for @qrFor.
  ///
  /// In en, this message translates to:
  /// **'UPI QR code for {payee}'**
  String qrFor(String payee);

  /// No description provided for @payWithUpiApp.
  ///
  /// In en, this message translates to:
  /// **'Pay with UPI app'**
  String get payWithUpiApp;

  /// No description provided for @saveQr.
  ///
  /// In en, this message translates to:
  /// **'Save QR to gallery'**
  String get saveQr;

  /// No description provided for @copyUpiId.
  ///
  /// In en, this message translates to:
  /// **'Copy UPI ID'**
  String get copyUpiId;

  /// No description provided for @upiIdCopied.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied'**
  String get upiIdCopied;

  /// No description provided for @noUpiApp.
  ///
  /// In en, this message translates to:
  /// **'No UPI app found — scan or save the QR instead'**
  String get noUpiApp;

  /// No description provided for @qrSaved.
  ///
  /// In en, this message translates to:
  /// **'QR saved to your gallery — open it from your UPI app'**
  String get qrSaved;

  /// No description provided for @qrNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the QR — please allow photo access'**
  String get qrNotSaved;

  /// No description provided for @payStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to pay'**
  String get payStepsTitle;

  /// No description provided for @payStep1.
  ///
  /// In en, this message translates to:
  /// **'Pay exactly {amount} — tap Pay with UPI app, or scan the QR.'**
  String payStep1(String amount);

  /// No description provided for @payStep2.
  ///
  /// In en, this message translates to:
  /// **'Take a screenshot of the successful payment.'**
  String get payStep2;

  /// No description provided for @payStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the green button and attach the screenshot in WhatsApp.'**
  String get payStep3;

  /// No description provided for @utrHint.
  ///
  /// In en, this message translates to:
  /// **'UPI reference / UTR no. (optional)'**
  String get utrHint;

  /// No description provided for @sendProof.
  ///
  /// In en, this message translates to:
  /// **'Send payment proof on WhatsApp'**
  String get sendProof;

  /// No description provided for @sendProofNote.
  ///
  /// In en, this message translates to:
  /// **'Sends to {number}. We’ll confirm your order once the payment is checked.'**
  String sendProofNote(String number);

  /// No description provided for @beingPacked.
  ///
  /// In en, this message translates to:
  /// **'Being packed'**
  String get beingPacked;

  /// No description provided for @buyAgain.
  ///
  /// In en, this message translates to:
  /// **'Buy again'**
  String get buyAgain;

  /// No description provided for @buyAgainNone.
  ///
  /// In en, this message translates to:
  /// **'These items are sold out right now'**
  String get buyAgainNone;

  /// No description provided for @buyAgainSome.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added — the rest are sold out} other{{count} items added — the rest are sold out}}'**
  String buyAgainSome(int count);

  /// No description provided for @cancelExchangeQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this exchange?'**
  String get cancelExchangeQ;

  /// No description provided for @cancelReturnQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this return?'**
  String get cancelReturnQ;

  /// No description provided for @cancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'The courier pickup will be called off too.'**
  String get cancelRequestBody;

  /// No description provided for @cancelNoChargeNote.
  ///
  /// In en, this message translates to:
  /// **'No payment has been confirmed for this order, so nothing will be charged.'**
  String get cancelNoChargeNote;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelPackedNote.
  ///
  /// In en, this message translates to:
  /// **'Your parcel is packed. Cancelling now also cancels the courier pickup.'**
  String get cancelPackedNote;

  /// No description provided for @cancelRefundNote.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} will be refunded to the UPI account you paid from.'**
  String cancelRefundNote(String amount);

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelledNothingCharged.
  ///
  /// In en, this message translates to:
  /// **'Cancelled · nothing was charged'**
  String get cancelledNothingCharged;

  /// No description provided for @cancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {date}'**
  String cancelledOn(String date);

  /// No description provided for @cancelledRefundPending.
  ///
  /// In en, this message translates to:
  /// **'Cancelled · {amount} refund on the way'**
  String cancelledRefundPending(String amount);

  /// No description provided for @cancelledRefunded.
  ///
  /// In en, this message translates to:
  /// **'Cancelled · {amount} refunded'**
  String cancelledRefunded(String amount);

  /// No description provided for @deliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered {date}'**
  String deliveredOn(String date);

  /// No description provided for @deliveredReturnUntil.
  ///
  /// In en, this message translates to:
  /// **'Delivered {date} · return until {until}'**
  String deliveredReturnUntil(String date, String until);

  /// No description provided for @deliveringToCaps.
  ///
  /// In en, this message translates to:
  /// **'DELIVERING TO'**
  String get deliveringToCaps;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @exchangeIt.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchangeIt;

  /// No description provided for @exchangeNote.
  ///
  /// In en, this message translates to:
  /// **'We’ll pick up the item and send you a replacement — no extra charge.'**
  String get exchangeNote;

  /// No description provided for @exchangeRequested.
  ///
  /// In en, this message translates to:
  /// **'Exchange requested — we’ll be in touch'**
  String get exchangeRequested;

  /// No description provided for @exchangeWord.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchangeWord;

  /// No description provided for @helpMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello Nirmal Mart, I need help with my order {number}.'**
  String helpMessage(String number);

  /// No description provided for @inReturn.
  ///
  /// In en, this message translates to:
  /// **'{count} in return'**
  String inReturn(int count);

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @myOrdersAlt.
  ///
  /// In en, this message translates to:
  /// **'माझ्या ऑर्डर्स'**
  String get myOrdersAlt;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @noOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'When you order something, you’ll find it here.'**
  String get noOrdersBody;

  /// No description provided for @noOrdersHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get noOrdersHere;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @orderConfirmedLine.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed · we’ll pack it soon'**
  String get orderConfirmedLine;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @ordersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ordersActive;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String ordersCount(int count);

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Payment: {method}'**
  String paidBy(String method);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @payToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} to confirm your order'**
  String payToConfirm(String amount);

  /// No description provided for @payToConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll start packing once your UPI payment is checked.'**
  String get payToConfirmBody;

  /// No description provided for @pickItemsAndReason.
  ///
  /// In en, this message translates to:
  /// **'Choose the items and a reason'**
  String get pickItemsAndReason;

  /// No description provided for @pickReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get pickReason;

  /// No description provided for @placedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed {when}'**
  String placedOn(String when);

  /// No description provided for @plusMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String plusMore(int count);

  /// No description provided for @qtyPrice.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty} · {price}'**
  String qtyPrice(int qty, String price);

  /// No description provided for @rateItems.
  ///
  /// In en, this message translates to:
  /// **'Rate items'**
  String get rateItems;

  /// No description provided for @refundDone.
  ///
  /// In en, this message translates to:
  /// **'{amount} refunded to your UPI account'**
  String refundDone(String amount);

  /// No description provided for @refundOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'{amount} refund on the way to your UPI account'**
  String refundOnTheWay(String amount);

  /// No description provided for @refundToUpi.
  ///
  /// In en, this message translates to:
  /// **'refund {amount} to your UPI'**
  String refundToUpi(String amount);

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @requestExchange.
  ///
  /// In en, this message translates to:
  /// **'Request exchange'**
  String get requestExchange;

  /// No description provided for @requestReturn.
  ///
  /// In en, this message translates to:
  /// **'Request return'**
  String get requestReturn;

  /// No description provided for @retApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get retApproved;

  /// No description provided for @retExchanged.
  ///
  /// In en, this message translates to:
  /// **'Exchanged'**
  String get retExchanged;

  /// No description provided for @retPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get retPickedUp;

  /// No description provided for @retPickupScheduled.
  ///
  /// In en, this message translates to:
  /// **'Pickup scheduled'**
  String get retPickupScheduled;

  /// No description provided for @retReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get retReceived;

  /// No description provided for @retRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get retRefunded;

  /// No description provided for @retRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get retRejected;

  /// No description provided for @retRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get retRequested;

  /// No description provided for @returnCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else we should know? (optional)'**
  String get returnCommentHint;

  /// No description provided for @returnExchange.
  ///
  /// In en, this message translates to:
  /// **'Return / exchange'**
  String get returnExchange;

  /// No description provided for @returnForRefund.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnForRefund;

  /// No description provided for @returnInProgressLine.
  ///
  /// In en, this message translates to:
  /// **'Return or exchange in progress'**
  String get returnInProgressLine;

  /// No description provided for @returnNote.
  ///
  /// In en, this message translates to:
  /// **'We’ll pick it up from your address. {amount} will be refunded to your UPI once it reaches us.'**
  String returnNote(String amount);

  /// No description provided for @returnNoteNoAmount.
  ///
  /// In en, this message translates to:
  /// **'We’ll pick it up from your address and refund you once it reaches us.'**
  String get returnNoteNoAmount;

  /// No description provided for @returnRequested.
  ///
  /// In en, this message translates to:
  /// **'Return requested — we’ll be in touch'**
  String get returnRequested;

  /// No description provided for @returnUntilDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Return or exchange until {date} · 1 day left} other{Return or exchange until {date} · {days} days left}}'**
  String returnUntilDays(String date, int days);

  /// No description provided for @returnUntilToday.
  ///
  /// In en, this message translates to:
  /// **'Return or exchange until {date} · last day'**
  String returnUntilToday(String date);

  /// No description provided for @returnWord.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnWord;

  /// No description provided for @sendProofShort.
  ///
  /// In en, this message translates to:
  /// **'Send proof'**
  String get sendProofShort;

  /// No description provided for @stAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get stAwaitingPayment;

  /// No description provided for @stCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get stCancelled;

  /// No description provided for @stConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stConfirmed;

  /// No description provided for @stDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stDelivered;

  /// No description provided for @stPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get stPacked;

  /// No description provided for @stRefundPending.
  ///
  /// In en, this message translates to:
  /// **'Refund pending'**
  String get stRefundPending;

  /// No description provided for @stRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get stRefunded;

  /// No description provided for @stReturnInProgress.
  ///
  /// In en, this message translates to:
  /// **'Return in progress'**
  String get stReturnInProgress;

  /// No description provided for @stShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get stShipped;

  /// No description provided for @statusCaps.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusCaps;

  /// No description provided for @stepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stepConfirmed;

  /// No description provided for @stepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// No description provided for @stepPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get stepPacked;

  /// No description provided for @stepPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get stepPlaced;

  /// No description provided for @stepShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get stepShipped;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @trackPickup.
  ///
  /// In en, this message translates to:
  /// **'Track pickup'**
  String get trackPickup;

  /// No description provided for @upiPending.
  ///
  /// In en, this message translates to:
  /// **'UPI (pending)'**
  String get upiPending;

  /// No description provided for @whatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What’s the reason?'**
  String get whatsWrong;

  /// No description provided for @whichItems.
  ///
  /// In en, this message translates to:
  /// **'Which items?'**
  String get whichItems;

  /// No description provided for @whyCancel.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get whyCancel;

  /// No description provided for @addedToBagCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added to bag} other{{count} items added to bag}}'**
  String addedToBagCount(int count);

  /// No description provided for @wishlistShareTitle.
  ///
  /// In en, this message translates to:
  /// **'My Nirmal Mart wishlist 🛒'**
  String get wishlistShareTitle;

  /// No description provided for @wishlistGuest.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone only. Sign in to keep it on every device.'**
  String get wishlistGuest;

  /// No description provided for @priceDropBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is cheaper than when you saved it} other{{count} items are cheaper than when you saved them}}'**
  String priceDropBanner(int count);

  /// No description provided for @wishlistAlt.
  ///
  /// In en, this message translates to:
  /// **'विशलिस्ट'**
  String get wishlistAlt;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedCount(int count);

  /// No description provided for @addAllToBag.
  ///
  /// In en, this message translates to:
  /// **'Add all to bag'**
  String get addAllToBag;

  /// No description provided for @movedToBag.
  ///
  /// In en, this message translates to:
  /// **'Moved to bag'**
  String get movedToBag;

  /// No description provided for @inYourBag.
  ///
  /// In en, this message translates to:
  /// **'In your bag'**
  String get inYourBag;

  /// No description provided for @moveToBag.
  ///
  /// In en, this message translates to:
  /// **'Move to bag'**
  String get moveToBag;

  /// No description provided for @priceDropped.
  ///
  /// In en, this message translates to:
  /// **'Price dropped {amount}'**
  String priceDropped(String amount);

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the ♡ on any product to save it here for later.'**
  String get wishlistEmptyBody;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore products'**
  String get exploreProducts;

  /// No description provided for @accountCaps.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountCaps;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeleted;

  /// No description provided for @accountGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track orders and keep your bag and wishlist on every device.'**
  String get accountGuestBody;

  /// No description provided for @accountHello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get accountHello;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address removed'**
  String get addressDeleted;

  /// No description provided for @addressesTile.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addressesTile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @awaitingPaymentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 awaiting payment} other{{count} awaiting payment}}'**
  String awaitingPaymentCount(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @defaultSet.
  ///
  /// In en, this message translates to:
  /// **'Default address updated'**
  String get defaultSet;

  /// No description provided for @defaultTag.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get defaultTag;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQ;

  /// No description provided for @deleteAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountSub;

  /// No description provided for @deleteAddressQ.
  ///
  /// In en, this message translates to:
  /// **'Remove this address?'**
  String get deleteAddressQ;

  /// No description provided for @deleteEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteEnterPassword;

  /// No description provided for @deleteKeepsOrders.
  ///
  /// In en, this message translates to:
  /// **'Order records are kept without your contact details, as required for GST and returns. Orders still on their way must be delivered or cancelled first.'**
  String get deleteKeepsOrders;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deletePoint1.
  ///
  /// In en, this message translates to:
  /// **'Your name, email, mobile, saved addresses, bag and wishlist are erased.'**
  String get deletePoint1;

  /// No description provided for @deletePoint2.
  ///
  /// In en, this message translates to:
  /// **'You’ll be signed out and can’t sign in to this account again.'**
  String get deletePoint2;

  /// No description provided for @deletePoint3.
  ///
  /// In en, this message translates to:
  /// **'This can’t be undone. You can create a new account later with the same email.'**
  String get deletePoint3;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddress;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @emailCantChange.
  ///
  /// In en, this message translates to:
  /// **'Email can’t be changed'**
  String get emailCantChange;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @helpCaps.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get helpCaps;

  /// No description provided for @helpGeneral.
  ///
  /// In en, this message translates to:
  /// **'Hello Nirmal Mart, I have a question.'**
  String get helpGeneral;

  /// No description provided for @keepMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get keepMyAccount;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @makeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make default'**
  String get makeDefault;

  /// No description provided for @myStuffCaps.
  ///
  /// In en, this message translates to:
  /// **'MY STUFF'**
  String get myStuffCaps;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @noAddressesBody.
  ///
  /// In en, this message translates to:
  /// **'Add one now and checkout will be quicker.'**
  String get noAddressesBody;

  /// No description provided for @noAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noAddressesYet;

  /// No description provided for @ordersTile.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTile;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don’t match'**
  String get passwordsDontMatch;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @perkFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster checkout with saved addresses'**
  String get perkFaster;

  /// No description provided for @perkSync.
  ///
  /// In en, this message translates to:
  /// **'Wishlist and bag saved to your account'**
  String get perkSync;

  /// No description provided for @perkTrack.
  ///
  /// In en, this message translates to:
  /// **'Track every order'**
  String get perkTrack;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @settingsCaps.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsCaps;

  /// No description provided for @shippingReturns.
  ///
  /// In en, this message translates to:
  /// **'Shipping & delivery'**
  String get shippingReturns;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your bag and wishlist stay saved in your account.'**
  String get signOutBody;

  /// No description provided for @signOutQ.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQ;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'version {v}'**
  String version(String v);

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'A new version of Nirmal Mart is ready. Restart to use it.'**
  String get updateReady;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @contactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUsTitle;

  /// No description provided for @contactUsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose whichever is easier for you.'**
  String get contactUsBody;

  /// No description provided for @contactUsSub.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp, email or call'**
  String get contactUsSub;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactWhatsAppSub.
  ///
  /// In en, this message translates to:
  /// **'Quickest — send photos too'**
  String get contactWhatsAppSub;

  /// No description provided for @contactCall.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get contactCall;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the dialer — call {phone}'**
  String callFailed(String phone);

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqTitle;

  /// No description provided for @stillQuestion.
  ///
  /// In en, this message translates to:
  /// **'Still have a question?'**
  String get stillQuestion;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get followUs;

  /// No description provided for @followUsSub.
  ///
  /// In en, this message translates to:
  /// **'New arrivals, offers and product videos'**
  String get followUsSub;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the link'**
  String get linkFailed;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get contactEmail;

  /// No description provided for @emailFailed.
  ///
  /// In en, this message translates to:
  /// **'No email app found — write to {email}'**
  String emailFailed(String email);

  /// No description provided for @helpEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Help with order {number}'**
  String helpEmailSubject(String number);

  /// No description provided for @adminNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Store admin'**
  String get adminNoteTitle;

  /// No description provided for @adminNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Orders, products, stock and settings are managed on the website.'**
  String get adminNoteBody;

  /// No description provided for @adminNoteOpen.
  ///
  /// In en, this message translates to:
  /// **'Open admin'**
  String get adminNoteOpen;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund & cancellation policy'**
  String get refundPolicy;

  /// No description provided for @upiRef.
  ///
  /// In en, this message translates to:
  /// **'UPI ref {ref}'**
  String upiRef(String ref);

  /// No description provided for @forgotEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we’ll send you a link to choose a new password.'**
  String get forgotEmailBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @resetSentBody.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account, we’ve sent a link to reset the password. It works for 1 hour — check spam too. After choosing a new password, sign in here.'**
  String resetSentBody(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get it? Send again'**
  String get resendLink;

  /// No description provided for @forgotNoEmailAccess.
  ///
  /// In en, this message translates to:
  /// **'Can’t get into your email? WhatsApp us'**
  String get forgotNoEmailAccess;

  /// No description provided for @notificationsCaps.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsCaps;

  /// No description provided for @notifOrders.
  ///
  /// In en, this message translates to:
  /// **'Order updates'**
  String get notifOrders;

  /// No description provided for @notifOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Payment, shipping, delivery and refunds'**
  String get notifOrdersSub;

  /// No description provided for @notifOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers & deals'**
  String get notifOffers;

  /// No description provided for @notifOffersSub.
  ///
  /// In en, this message translates to:
  /// **'Sales and new arrivals'**
  String get notifOffersSub;

  /// No description provided for @notifBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Nirmal Mart. Turn them on in your phone’s Settings → Apps → Nirmal Mart → Notifications.'**
  String get notifBlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
