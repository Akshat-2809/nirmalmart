import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/orders/order_detail_screen.dart';
import 'package:nirmal_mart/features/orders/orders_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'checkout_test.dart' show FakeLauncher;
import 'helpers.dart';

final _now = DateTime.now().toUtc();
String _iso(DateTime d) => d.toIso8601String();

Map<String, Object?> item(int id, int productId, String name, num price, {int qty = 1}) => {
      'id': id,
      'product_id': productId,
      'product_name': name,
      'product_slug': name.toLowerCase().replaceAll(' ', '-'),
      'product_image': null,
      'quantity': qty,
      'unit_price': price,
      'subtotal': price * qty,
    };

Map<String, Object?> order(
  int id, {
  String status = 'confirmed',
  String payment = 'paid',
  List<Map<String, Object?>>? items,
  num total = 750,
  String? awb,
  DateTime? deliveredAt,
  List<Map<String, Object?>> returns = const [],
  String? cancelReason,
}) {
  final its = items ?? [item(1, 8, 'LM 7703 Torch', 450), item(2, 4, 'Steel Bottle', 200, qty: 1), item(3, 5, 'Spice Rack', 100)];
  return {
    'id': id,
    'order_number': 'NM26112$id',
    'status': status,
    'payment_method': 'upi_qr',
    'payment_status': payment,
    'subtotal_amount': total,
    'tax_amount': 114.41,
    'shipping_amount': 0,
    'total_amount': total,
    'shipping_address': {'full_name': 'Ravi Patil', 'phone': '9876543210', 'address_line1': 'Flat 12', 'city': 'Kalyan', 'state': 'Maharashtra', 'postal_code': '421201'},
    'items': its,
    'awb_code': awb,
    'courier_name': awb == null ? null : 'Delhivery',
    'tracking_status': awb == null ? null : 'IN TRANSIT',
    'tracking_url': awb == null ? null : 'https://shiprocket.co/tracking/$awb',
    'delivered_at': deliveredAt == null ? null : _iso(deliveredAt),
    'return_until': deliveredAt == null ? null : _iso(deliveredAt.add(const Duration(days: 5))),
    'cancelled_at': status == 'cancelled' ? _iso(_now) : null,
    'cancel_reason': cancelReason,
    'returns': returns,
    'created_at': _iso(_now.subtract(Duration(days: id))),
    'updated_at': _iso(_now),
  };
}

/// Signed in, with these orders on the server; POSTs change them like the backend does
FakeApi ordersApi(List<Map<String, Object?>> orders) {
  Map<String, Object?> find(String path) => orders.firstWhere((o) => path.contains('/orders/${o['id']}'));
  return FakeApi({
    'GET /auth/me': (_) => (200, fakeUser()),
    'GET /cart': (_) => (200, {'items': [], 'total_items': 0, 'subtotal': 0, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 0, 'free_shipping_threshold': 499}),
    'GET /wishlist': (_) => (200, []),
    'GET /orders': (_) => (200, orders),
    'GET /orders/*': (o) => (200, find(o.path)),
    'POST /orders/*/cancel': (o) {
      final x = find(o.path);
      x['status'] = 'cancelled';
      x['cancel_reason'] = (o.data as Map?)?['reason'];
      x['cancelled_at'] = _iso(_now);
      return (200, x);
    },
    'POST /orders/*/returns': (o) {
      final x = find(o.path);
      final body = o.data as Map;
      x['returns'] = [
        ...(x['returns'] as List),
        {
          'id': 9,
          'kind': body['kind'],
          'items': [for (final i in body['items'] as List) {...(i as Map), 'product_name': 'Gas Stove'}],
          'reason': body['reason'],
          'status': 'requested',
          'refund_amount': body['kind'] == 'return' ? 1600 : null,
          'created_at': _iso(_now),
        },
      ];
      return (201, x);
    },
    'POST /orders/*/returns/*/cancel': (o) {
      final x = find(o.path);
      for (final r in x['returns'] as List) {
        (r as Map)['status'] = 'cancelled';
      }
      return (200, x);
    },
    'GET /cart/items': (_) => (200, {}),
    'POST /cart/items': (_) => (200, {'items': [], 'total_items': 1, 'subtotal': 450, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 450, 'free_shipping_threshold': 499}),
  }..addAll({for (final e in catalogueRoutes().entries) if (e.key == 'GET /products') e.key: e.value}));
}

Future<TestApp> start(WidgetTester tester, FakeApi api, {Map<String, Object> saved = onboarded}) =>
    startApp(tester, saved: saved, tokens: MemoryTokens()..accessToken = 'acc', api: api);

Future<void> go(WidgetTester tester, String path) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

/// Scrolls the screen (or open sheet) until [f] is built — up to the top first, then down —
/// and brings it into view
Future<void> reveal(WidgetTester tester, Finder f) async {
  final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = 0; i < 6 && f.evaluate().isEmpty; i++) {
    await tester.drag(page.last, const Offset(0, 400));
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 15 && f.evaluate().isEmpty; i++) {
    await tester.drag(page.last, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
}

Future<void> tapIt(WidgetTester tester, Finder f) async {
  await reveal(tester, f);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  late FakeLauncher launcher;
  setUp(() {
    launcher = FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  final delivered = order(4, status: 'delivered', items: [item(7, 9, 'Gas Stove', 1600), item(8, 2, 'Washer Gun', 150)], total: 1750, awb: 'AWB4', deliveredAt: _now.subtract(const Duration(days: 2)));
  List<Map<String, Object?>> sample() => [
        order(1, status: 'pending', payment: 'pending', total: 499),
        order(2, status: 'shipped', awb: '1490234567'),
        order(4, status: 'delivered', items: [item(7, 9, 'Gas Stove', 1600), item(8, 2, 'Washer Gun', 150)], total: 1750, awb: 'AWB4', deliveredAt: _now.subtract(const Duration(days: 2))),
        order(5, status: 'cancelled', payment: 'pending', cancelReason: 'Changed my mind'),
      ];

  testWidgets('guests are asked to sign in', (tester) async {
    await startApp(tester, saved: onboarded);
    await go(tester, '/account/orders');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('list: statuses, one-line summaries, filters', (tester) async {
    await start(tester, ordersApi(sample()));
    await go(tester, '/account/orders');
    expect(find.byType(OrdersScreen), findsOneWidget);
    expect(find.text('My orders'), findsOneWidget);
    expect(find.text('Awaiting payment'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
    expect(find.text('Shipped'), findsWidgets);
    expect(find.text('In Transit'), findsOneWidget);
    expect(find.textContaining('return until'), findsOneWidget);
    await reveal(tester, find.text('Cancelled · nothing was charged'));

    await tapIt(tester, find.widgetWithText(ChoiceChip, 'Delivered'));
    expect(find.text('NM261124'), findsOneWidget);
    expect(find.text('NM261121'), findsNothing);
    await tapIt(tester, find.widgetWithText(ChoiceChip, 'Cancelled'));
    expect(find.text('NM261125'), findsOneWidget);
    await tapIt(tester, find.widgetWithText(ChoiceChip, 'Active'));
    expect(find.text('NM261121'), findsOneWidget);
    expect(find.text('NM261122'), findsOneWidget);
  });

  testWidgets('no orders yet', (tester) async {
    await start(tester, ordersApi([]));
    await go(tester, '/account/orders');
    expect(find.text('No orders yet'), findsOneWidget);
    await tapIt(tester, find.text('Start shopping'));
    expect(find.byType(OrdersScreen), findsNothing);
  });

  testWidgets('Pay now on the list opens the UPI panel', (tester) async {
    await start(tester, ordersApi(sample()));
    await go(tester, '/account/orders');
    await tapIt(tester, find.text('Pay now'));
    expect(find.text('Pay ₹499 by UPI'), findsOneWidget);
    await tapIt(tester, find.text('Pay with UPI app'));
    expect(Uri.parse(launcher.urls.last).queryParameters['am'], '499.00');
  });

  testWidgets('unpaid order: pay card, send proof, cancel with a reason', (tester) async {
    final api = ordersApi(sample());
    await start(tester, api);
    await go(tester, '/account/orders/1');
    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('Pay ₹499 to confirm your order'), findsOneWidget);
    await tapIt(tester, find.text('Send proof'));
    expect(Uri.parse(launcher.urls.last).queryParameters['text'], contains('Order ID: NM261121'));

    await tapIt(tester, find.widgetWithText(OutlinedButton, 'Cancel order'));
    expect(find.text('Why are you cancelling?'), findsOneWidget);
    expect(find.text('No payment has been confirmed for this order, so nothing will be charged.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cancel order')).onPressed, isNull);
    await tapIt(tester, find.text('Changed my mind'));
    await tapIt(tester, find.widgetWithText(FilledButton, 'Cancel order'));
    expect(api.requests.lastWhere((r) => r.method == 'POST').data, {'reason': 'Changed my mind'});
    expect(find.text('Order cancelled'), findsOneWidget);
    await reveal(tester, find.text('Changed my mind')); // shown on the cancelled card
    expect(find.text('Pay now'), findsNothing);
  });

  testWidgets('shipped: timeline, courier and Track, no cancel', (tester) async {
    await start(tester, ordersApi(sample()));
    await go(tester, '/account/orders/2');
    expect(find.text('In Transit · Delhivery'), findsOneWidget);
    expect(find.text('AWB 1490234567'), findsOneWidget);
    await tapIt(tester, find.text('Track ↗'));
    expect(launcher.urls.last, 'https://shiprocket.co/tracking/1490234567');
    await tapIt(tester, find.text('Need help?'));
    await tapIt(tester, find.text('Chat on WhatsApp')); // asks WhatsApp or Call first
    expect(Uri.parse(launcher.urls.last).path, '/917498299375');
    expect(Uri.parse(launcher.urls.last).queryParameters['text'], contains('NM261122'));
  });

  testWidgets('delivered: return window, request a return, then cancel the request', (tester) async {
    final api = ordersApi([Map.of(delivered)]);
    await start(tester, api);
    await go(tester, '/account/orders/4');
    expect(find.textContaining('days left'), findsOneWidget);
    await tapIt(tester, find.text('Return / exchange'));
    final submit = find.widgetWithText(FilledButton, 'Request return');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tapIt(tester, find.byType(Checkbox).first); // Gas Stove
    await tapIt(tester, find.text('Item is damaged or defective'));
    expect(find.textContaining('₹1,600 will be refunded'), findsOneWidget);
    await tapIt(tester, submit);
    final post = api.requests.lastWhere((r) => r.method == 'POST').data as Map;
    expect(post['kind'], 'return');
    expect(post['items'], [{'order_item_id': 7, 'quantity': 1}]);
    expect(post['reason'], 'Item is damaged or defective');
    expect(find.text('Return requested — we’ll be in touch'), findsOneWidget);
    expect(find.text('Return · Gas Stove'), findsOneWidget);
    expect(find.textContaining('1 in return'), findsOneWidget);

    await tapIt(tester, find.text('Cancel request'));
    await tapIt(tester, find.widgetWithText(TextButton, 'Cancel request').last);
    expect(api.requests.lastWhere((r) => r.method == 'POST').path, '/orders/4/returns/9/cancel');
    expect(find.text('Request cancelled'), findsOneWidget);
  });

  testWidgets('exchange has its own reasons', (tester) async {
    await start(tester, ordersApi([Map.of(delivered)]));
    await go(tester, '/account/orders/4');
    await tapIt(tester, find.text('Return / exchange'));
    await tapIt(tester, find.text('Exchange'));
    expect(find.text('Wrong size'), findsOneWidget);
    expect(find.text('No longer needed'), findsNothing);
    expect(find.text('Request exchange'), findsOneWidget);
  });

  testWidgets('return window closed: no return button', (tester) async {
    final old = order(4, status: 'delivered', deliveredAt: _now.subtract(const Duration(days: 9)));
    await start(tester, ordersApi([old]));
    await go(tester, '/account/orders/4');
    await reveal(tester, find.text('Rate items'));
    expect(find.text('Return / exchange'), findsNothing);
  });

  testWidgets('Buy again puts what is on sale back in the bag', (tester) async {
    final api = ordersApi(sample());
    await start(tester, api);
    await go(tester, '/account/orders/2');
    await tapIt(tester, find.text('Buy again'));
    final adds = api.requests.where((r) => r.method == 'POST' && r.path == '/cart/items').map((r) => (r.data as Map)['product_id']).toList();
    expect(adds, [8, 4, 5]);
    expect(find.text('Added to bag'), findsOneWidget);
  });

  testWidgets('View order on the order-placed screen opens the order', (tester) async {
    await start(tester, ordersApi(sample()));
    await go(tester, '/order/1/placed');
    await tapIt(tester, find.text('View order'));
    expect(find.byType(OrderDetailScreen), findsOneWidget);
  });

  testWidgets('Marathi', (tester) async {
    await start(tester, ordersApi(sample()), saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
    await go(tester, '/account/orders');
    expect(find.text('माझ्या ऑर्डर्स'), findsOneWidget);
    expect(find.text('पेमेंट बाकी'), findsWidgets);
    await go(tester, '/account/orders/4');
    await reveal(tester, find.text('परत / बदल'));
  });

  for (final dark in [false, true]) {
    testWidgets('small phone with large text${dark ? ', dark' : ''}: no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await start(tester, ordersApi(sample()));
      await go(tester, '/account/orders');
      expect(tester.takeException(), isNull);
      for (final id in [1, 2, 4, 5]) {
        await go(tester, '/account/orders/$id');
        expect(tester.takeException(), isNull, reason: 'order $id');
      }
      await tapIt(tester, find.text('Return / exchange').hitTestable().evaluate().isEmpty ? find.text('Buy again') : find.text('Return / exchange'));
      expect(tester.takeException(), isNull);
    });
  }
}
