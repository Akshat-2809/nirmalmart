import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// ₹1,499 — Indian grouping, no paise (same as the website's price())
String rupees(num v) => _inr.format(v);

final _inr2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// ₹129.66 — with paise, for tax lines (the website's priceExact())
String priceExact(num v) => _inr2.format(v);

/// A lighter copy of a product photo for small slots, same rule as the website's sized():
/// our uploads are `<id>.webp` (1200 px) with a `<id>_480.webp` thumbnail; Unsplash takes a width.
String sized(String url, int width) {
  if (url.contains('images.unsplash.com')) return url.replaceFirst(RegExp(r'w=\d+'), 'w=$width');
  if (width <= 600 && url.endsWith('.webp') && !url.endsWith('_480.webp')) {
    return url.replaceFirst(RegExp(r'\.webp$'), '_480.webp');
  }
  return url;
}

/// "Thu, 28 Nov" for [days] from today
String deliveryDate(int days, {DateTime? from}) =>
    DateFormat('EEE, d MMM').format((from ?? DateTime.now()).add(Duration(days: days)));
