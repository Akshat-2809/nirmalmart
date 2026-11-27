import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../format.dart';
import '../prefs.dart';
import '../validate.dart';

/// Ids of the last 12 products opened, newest first. Only ids are kept; names, prices and photos are
/// always fetched fresh (same as the website's useRecentlyViewed).
final recentIdsProvider = NotifierProvider<RecentIds, List<int>>(RecentIds.new);

class RecentIds extends Notifier<List<int>> {
  static const _key = 'nm_recent';

  @override
  List<int> build() => [
        for (final s in ref.watch(sharedPrefsProvider).getStringList(_key) ?? const <String>[]) ?int.tryParse(s),
      ];

  Future<void> push(int productId) async {
    state = [productId, ...state.where((id) => id != productId)].take(12).toList();
    await ref.read(sharedPrefsProvider).setStringList(_key, [for (final id in state) '$id']);
  }
}

/// Delivery pincode the shopper entered (shown as "Deliver to …" on Home)
final pincodeProvider = NotifierProvider<PincodeNotifier, String?>(PincodeNotifier.new);

class PincodeNotifier extends Notifier<String?> {
  static const _key = 'nm_pincode';

  @override
  String? build() => ref.watch(sharedPrefsProvider).getString(_key);

  Future<void> set(String pin) async {
    state = pin;
    await ref.read(sharedPrefsProvider).setString(_key, pin);
  }
}

/// Result of a pincode check: a delivery date, "we don't deliver there", or an invalid pincode
class DeliveryCheck {
  const DeliveryCheck.by(this.date) : unserviceable = false, invalid = false;
  const DeliveryCheck.unserviceable() : date = null, unserviceable = true, invalid = false;
  const DeliveryCheck.invalid() : date = null, unserviceable = false, invalid = true;

  final String? date;
  final bool unserviceable;
  final bool invalid;
}

/// Same as the website's product-page check: real courier times when Shiprocket is connected,
/// otherwise a rough built-in estimate (2 days for big metros, 4 elsewhere).
Future<DeliveryCheck> checkDelivery(ApiClient api, String pin) async {
  if (!Validate.isPincode(pin)) return const DeliveryCheck.invalid();
  try {
    final r = await api.dio.get<Map<String, dynamic>>('/shipping/estimate', queryParameters: {'pincode': pin});
    final est = r.data!;
    if (est['available'] == true) {
      if (est['serviceable'] == false) return const DeliveryCheck.unserviceable();
      if (est['min_days'] is int) return DeliveryCheck.by(deliveryDate(est['min_days'] as int));
    }
  } catch (_) {}
  const metros = {'11', '40', '56', '60', '70', '50'};
  return DeliveryCheck.by(deliveryDate(metros.contains(pin.substring(0, 2)) ? 2 : 4));
}
