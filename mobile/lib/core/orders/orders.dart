import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../cart/cart.dart';

/// A saved delivery address (GET /users/me/addresses)
class Address {
  Address.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        label = (j['label'] as String?) ?? 'Home',
        fullName = (j['full_name'] as String?) ?? '',
        phone = (j['phone'] as String?) ?? '',
        line1 = (j['address_line1'] as String?) ?? '',
        line2 = j['address_line2'] as String?,
        city = (j['city'] as String?) ?? '',
        state = (j['state'] as String?) ?? '',
        pincode = (j['postal_code'] as String?) ?? '',
        isDefault = j['is_default'] as bool? ?? false;

  final int id;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  /// "Flat 12, Shivaji Chowk, Kalyan, Maharashtra – 421201"
  String get oneLine => [line1, if (line2?.trim().isNotEmpty ?? false) line2!.trim(), city, '$state – $pincode'].join(', ');
}

/// New address, as the form sends it (same fields and rules as the website's AddressForm)
class AddressInput {
  const AddressInput({
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Map<String, Object?> toJson() => {
        'label': label,
        'full_name': fullName.trim(),
        'phone': phone,
        'address_line1': line1.trim(),
        if (line2?.trim().isNotEmpty ?? false) 'address_line2': line2!.trim(),
        'city': city.trim(),
        'state': state,
        'postal_code': pincode,
        'country': 'India',
        'is_default': isDefault,
      };
}

final addressesProvider = AsyncNotifierProvider<AddressesController, List<Address>>(AddressesController.new);

class AddressesController extends AsyncNotifier<List<Address>> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<List<Address>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return const [];
    final r = await _api.dio.get<List<dynamic>>('/users/me/addresses');
    return [for (final a in r.data!) Address.fromJson(a as Map<String, dynamic>)];
  }

  Future<Address> edit(int id, AddressInput input) async {
    final r = await _api.dio.put<Map<String, dynamic>>('/users/me/addresses/$id', data: input.toJson());
    ref.invalidateSelf();
    return Address.fromJson(r.data!);
  }

  Future<void> remove(int id) async {
    await _api.dio.delete('/users/me/addresses/$id');
    ref.invalidateSelf();
  }

  Future<void> makeDefault(Address a) => edit(a.id, AddressInput(
        label: a.label,
        fullName: a.fullName,
        phone: a.phone,
        line1: a.line1,
        line2: a.line2,
        city: a.city,
        state: a.state,
        pincode: a.pincode,
        isDefault: true,
      ));

  /// Saves a new address and returns it. Throws DioException if the server refuses.
  Future<Address> add(AddressInput input) async {
    final r = await _api.dio.post<Map<String, dynamic>>('/users/me/addresses', data: input.toJson());
    final a = Address.fromJson(r.data!);
    final before = state.value ?? const <Address>[];
    state = AsyncData([...before.map((x) => a.isDefault ? x.copyWithDefault(false) : x), a]);
    return a;
  }
}

extension on Address {
  Address copyWithDefault(bool v) => Address.fromJson({
        'id': id,
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'address_line1': line1,
        'address_line2': line2,
        'city': city,
        'state': state,
        'postal_code': pincode,
        'is_default': v,
      });
}

class OrderLine {
  OrderLine.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int? ?? 0,
        productId = j['product_id'] as int?,
        name = j['product_name'] as String,
        slug = j['product_slug'] as String?,
        image = j['product_image'] as String?,
        quantity = j['quantity'] as int,
        unitPrice = (j['unit_price'] as num).toDouble(),
        subtotal = (j['subtotal'] as num).toDouble();

  final int id;
  final int? productId;
  final String name;
  final String? slug;
  final String? image;
  final int quantity;
  final double unitPrice;
  final double subtotal;
}

/// An order (POST /orders, GET /orders/{id})
class Order {
  Order.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        number = j['order_number'] as String,
        status = j['status'] as String,
        paymentStatus = j['payment_status'] as String,
        subtotal = (j['subtotal_amount'] as num).toDouble(),
        tax = (j['tax_amount'] as num).toDouble(),
        shipping = (j['shipping_amount'] as num).toDouble(),
        total = (j['total_amount'] as num).toDouble(),
        shipTo = (j['shipping_address'] as Map?)?.cast<String, dynamic>(),
        items = [for (final i in (j['items'] as List? ?? const [])) OrderLine.fromJson(i as Map<String, dynamic>)],
        createdAt = _date(j['created_at']) ?? DateTime.now(),
        deliveredAt = _date(j['delivered_at']),
        cancelledAt = _date(j['cancelled_at']),
        refundedAt = _date(j['refunded_at']),
        returnUntil = _date(j['return_until']),
        awb = j['awb_code'] as String?,
        courier = j['courier_name'] as String?,
        trackingStatus = j['tracking_status'] as String?,
        trackingUrl = j['tracking_url'] as String?,
        cancelReason = j['cancel_reason'] as String?,
        refundReference = j['refund_reference'] as String?,
        returns = [for (final r in (j['returns'] as List? ?? const [])) ReturnRequest.fromJson(r as Map<String, dynamic>)];

  final int id;
  final String number;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final Map<String, dynamic>? shipTo;
  final List<OrderLine> items;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;

  /// Last moment to ask for a return or exchange (delivered orders only, 5 days)
  final DateTime? returnUntil;
  final String? awb;
  final String? courier;

  /// The courier's own words, e.g. "IN TRANSIT"
  final String? trackingStatus;
  final String? trackingUrl;
  final String? cancelReason;

  /// UPI reference of the refund, once sent
  final String? refundReference;
  final List<ReturnRequest> returns;

  static const steps = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

  bool get cancelled => status == 'cancelled';

  /// The customer can cancel until it ships (same rule as the backend)
  bool get canCancel => const {'pending', 'confirmed', 'processing'}.contains(status);

  bool get canReturn => returnUntil != null && DateTime.now().isBefore(returnUntil!) && returnableLines.isNotEmpty;

  bool get hasOpenReturn => returns.any((r) => r.open);

  /// Units of each line not already in a return/exchange request (rejected/cancelled ones don't count)
  Map<int, int> get returnableLines {
    final used = <int, int>{};
    for (final r in returns.where((r) => r.status != 'rejected' && r.status != 'cancelled')) {
      for (final i in r.items) {
        used[i.orderItemId] = (used[i.orderItemId] ?? 0) + i.quantity;
      }
    }
    return {for (final l in items) if (l.quantity - (used[l.id] ?? 0) > 0) l.id: l.quantity - (used[l.id] ?? 0)};
  }

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  /// Still waiting for the customer's UPI payment (same rule as the website's awaitingUpi)
  bool get awaitingPayment => paymentStatus == 'pending' && status != 'cancelled';

  String? get customerName => shipTo?['full_name'] as String?;
}

/// Places the order for everything in the bag, to [addressId]. The server checks stock and prices
/// and empties the bag. Throws DioException with the reason if it can't.
Future<Order> placeOrder(WidgetRef ref, {required int addressId, String? notes}) async {
  final r = await ref.read(apiClientProvider).dio.post<Map<String, dynamic>>('/orders', data: {
    'address_id': addressId,
    if (notes?.trim().isNotEmpty ?? false) 'notes': notes!.trim(),
  });
  ref.invalidate(cartProvider);
  return Order.fromJson(r.data!);
}

final orderProvider = FutureProvider.family<Order, int>((ref, id) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/orders/$id');
  return Order.fromJson(r.data!);
});

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

class ReturnLine {
  ReturnLine.fromJson(Map<String, dynamic> j)
      : orderItemId = (j['order_item_id'] as num?)?.toInt() ?? 0,
        quantity = (j['quantity'] as num?)?.toInt() ?? 0,
        name = j['product_name'] as String?;

  final int orderItemId;
  final int quantity;
  final String? name;
}

/// A return or exchange request on a delivered order
class ReturnRequest {
  ReturnRequest.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        kind = j['kind'] as String,
        items = [for (final i in (j['items'] as List? ?? const [])) ReturnLine.fromJson((i as Map).cast<String, dynamic>())],
        reason = (j['reason'] as String?) ?? '',
        comment = j['comment'] as String?,
        status = j['status'] as String,
        adminNote = j['admin_note'] as String?,
        refundAmount = (j['refund_amount'] as num?)?.toDouble(),
        refundReference = j['refund_reference'] as String?,
        pickupTrackingUrl = j['return_tracking_url'] as String?,
        replacementTrackingUrl = j['repl_tracking_url'] as String?;

  final int id;

  /// "return" or "exchange"
  final String kind;
  final List<ReturnLine> items;
  final String reason;
  final String? comment;
  final String status;
  final String? adminNote;
  final double? refundAmount;
  final String? refundReference;
  final String? pickupTrackingUrl;
  final String? replacementTrackingUrl;

  static const progress = ['requested', 'approved', 'pickup_scheduled', 'picked_up', 'received', 'completed'];

  bool get open => const {'requested', 'approved', 'pickup_scheduled', 'picked_up', 'received'}.contains(status);
  bool get exchange => kind == 'exchange';

  /// Until the courier has the parcel (same rule as the backend)
  bool get canCancel => const {'requested', 'approved', 'pickup_scheduled'}.contains(status);
}

/// The signed-in customer's orders, newest first
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return const [];
  final r = await ref.watch(apiClientProvider).dio.get<List<dynamic>>('/orders');
  return [for (final o in r.data!) Order.fromJson(o as Map<String, dynamic>)];
});

/// Order changes (cancel, return) go to the server and refresh the order and the list
class OrderActions {
  OrderActions(this.ref);

  final WidgetRef ref;

  Future<Order> _do(int id, Future<dynamic> Function(ApiClient api) call) async {
    final r = await call(ref.read(apiClientProvider));
    ref.invalidate(orderProvider(id));
    ref.invalidate(ordersProvider);
    return Order.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<Order> cancel(int id, String? reason) =>
      _do(id, (api) => api.dio.post('/orders/$id/cancel', data: {'reason': ?reason}));

  Future<Order> requestReturn(int id, {required String kind, required Map<int, int> items, required String reason, String? comment}) =>
      _do(id, (api) => api.dio.post('/orders/$id/returns', data: {
            'kind': kind,
            'items': [for (final e in items.entries) if (e.value > 0) {'order_item_id': e.key, 'quantity': e.value}],
            'reason': reason,
            if (comment?.trim().isNotEmpty ?? false) 'comment': comment!.trim(),
          }));

  Future<Order> cancelReturn(int id, int returnId) => _do(id, (api) => api.dio.post('/orders/$id/returns/$returnId/cancel'));
}
