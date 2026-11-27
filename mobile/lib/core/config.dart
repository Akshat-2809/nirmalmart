/// App-wide constants. Values that differ per build come from --dart-define.
abstract final class AppConfig {
  /// The same API the website uses. Going through www.nirmalmart.in (Vercel proxies /api to Render)
  /// keeps the app working even if the backend host changes again.
  /// Local backend: flutter run --dart-define=API_URL=http://10.0.2.2:8010/api  (10.0.2.2 = the Mac, from the Android emulator)
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://www.nirmalmart.in/api');

  static const siteUrl = 'https://www.nirmalmart.in';

  /// Store contacts (same as frontend/src/lib/contact.js)
  static const supportWhatsApp = '917498299375'; // general help (+91 74982 99375)
  static const supportPhone = '+917498299375';
  static const supportPhoneDisplay = '+91 74982 99375';

  /// Email: support for orders, returns, accounts and data; offers are sent from promotions@
  static const supportEmail = 'support@nirmalmart.in';

  /// Social pages (same as frontend/src/lib/contact.js SOCIAL)
  static const instagram = 'https://www.instagram.com/nirmalmart09';
  static const facebook = 'https://www.facebook.com/share/1GUyQxBTdf/';
  static const youtube = 'https://www.youtube.com/@NirmalMart';
  static const paymentWhatsApp = '919022230687'; // UPI payment proof (+91 90222 30687)
  static const paymentWhatsAppDisplay = '+91 90222 30687';

  /// UPI QR payments (same as frontend/src/lib/contact.js PAYMENT)
  static const upiId = 'vyapar.175693393199@hdfcbank';
  static const upiPayee = 'NIRMAL MART';
  static const upiQrAsset = 'assets/images/upi-qr.jpg';

  /// Store rules (mirrors backend/app/config.py — the server stays the source of truth for totals)
  static const freeDeliveryThreshold = 499;
  static const deliveryFee = 49;
  static const returnWindowDays = 5;
}
