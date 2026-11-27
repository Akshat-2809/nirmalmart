import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/checkout/checkout_screen.dart';
import 'package:nirmal_mart/features/checkout/order_placed_screen.dart';
import 'package:nirmal_mart/features/home/home_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers.dart';

/// Records links instead of opening apps
class FakeLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  final urls = <String>[];
  bool canOpen = true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return canOpen;
  }

  @override
  Future<bool> canLaunch(String url) async => canOpen;
}

Map<String, Object?> address(int id, {String name = 'Ravi Patil', String label = 'Home', bool isDefault = false, String pin = '421201'}) => {
      'id': id,
      'label': label,
      'full_name': name,
      'phone': '9876543210',
      'address_line1': 'Flat 12, Sai Darshan',
      'address_line2': 'Shivaji Chowk',
      'city': 'Kalyan',
      'state': 'Maharashtra',
      'postal_code': pin,
      'country': 'India',
      'is_default': isDefault,
    };

Map<String, Object?> serverCart({int qty = 1, int stock = 10}) => {
      'items': [
        {'id': 51, 'product_id': 1, 'product_name': 'Vacuum Cleaner', 'product_name_mr': 'व्हॅक्यूम क्लीनर', 'product_slug': 'vacuum-cleaner', 'product_price': 850, 'compare_at_price': 2100, 'product_image': null, 'stock_quantity': stock, 'quantity': qty, 'subtotal': 850 * qty},
      ],
      'total_items': qty,
      'subtotal': 850 * qty,
      'tax_amount': 129.66 * qty,
      'shipping_amount': 0,
      'total_amount': 850 * qty,
      'free_shipping_threshold': 499,
    };

Map<String, Object?> order({String status = 'pending', String payment = 'pending'}) => {
      'id': 77,
      'order_number': 'NM-482913',
      'status': status,
      'payment_method': 'upi_qr',
      'payment_status': payment,
      'subtotal_amount': 850,
      'tax_amount': 129.66,
      'shipping_amount': 0,
      'total_amount': 850,
      'shipping_address': {'full_name': 'Ravi Patil'},
      'items': [
        {'id': 1, 'product_id': 1, 'product_name': 'Vacuum Cleaner', 'product_slug': 'vacuum-cleaner', 'product_image': null, 'quantity': 1, 'unit_price': 850, 'subtotal': 850},
      ],
    };

/// A signed-in shopper with one thing in the bag
FakeApi signedInApi({List<Map<String, Object?>>? addresses, Map<String, FakeReply Function(dynamic)>? more}) {
  final saved = [...?addresses];
  return FakeApi({
    'GET /auth/me': (_) => (200, fakeUser()),
    'GET /cart': (_) => (200, serverCart()),
    'GET /wishlist': (_) => (200, []),
    'GET /users/me/addresses': (_) => (200, saved),
    'POST /users/me/addresses': (o) {
      final a = {...(o.data as Map).cast<String, Object?>(), 'id': 90 + saved.length};
      saved.add(a);
      return (201, a);
    },
    'POST /orders': (_) => (201, order()),
    'GET /orders/77': (_) => (200, order()),
    'GET /shipping/estimate': (_) => (200, {'available': true, 'serviceable': true, 'min_days': 3}),
    ...?more?.map((k, v) => MapEntry(k, (o) => v(o))),
  });
}

Future<TestApp> start(WidgetTester tester, FakeApi api, {Map<String, Object> saved = onboarded}) =>
    startApp(tester, saved: saved, tokens: MemoryTokens()..accessToken = 'acc', api: api);

Future<void> go(WidgetTester tester, String path) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

Finder get placeButton => find.ancestor(of: find.textContaining('Place order'), matching: find.byType(FilledButton));

Future<void> tapIt(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
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

  group('Sign-in check', () {
    testWidgets('a guest opening Checkout is asked to sign in, then lands on Checkout', (tester) async {
      final api = FakeApi({
        'POST /auth/login': (_) => (200, fakeTokens()),
        'GET /cart': (_) => (200, serverCart()),
        'GET /wishlist': (_) => (200, []),
        'GET /users/me/addresses': (_) => (200, [address(1, isDefault: true)]),
      });
      await startApp(tester, saved: onboarded, api: api);
      await go(tester, '/checkout');
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).from, '/checkout');

      await tester.enterText(find.widgetWithText(TextFormField, 'Email or username'), 'ravi@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Secret@123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Ravi Patil'), findsOneWidget);
    });

    testWidgets('order pages need sign-in too', (tester) async {
      await startApp(tester, saved: onboarded);
      await go(tester, '/order/77/placed');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OrderPlacedScreen), findsNothing);
    });

    testWidgets('a saved login is waited for, not bounced to Sign in', (tester) async {
      await start(tester, signedInApi(addresses: [address(1, isDefault: true)]));
      await go(tester, '/checkout');
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('Checkout', () {
    testWidgets('default address, items, UPI, summary; Change picks another address', (tester) async {
      await start(tester, signedInApi(addresses: [address(1, isDefault: true), address(2, name: 'Sunita Patil', label: 'Work', pin: '400001')]));
      await go(tester, '/checkout');
      expect(find.text('DELIVER TO'), findsOneWidget);
      expect(find.text('Ravi Patil'), findsOneWidget);
      expect(find.textContaining('Kalyan, Maharashtra – 421201'), findsOneWidget);
      expect(find.textContaining('🚚 Delivery by'), findsOneWidget);
      expect(find.text('1 ITEM'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      await tester.dragUntilVisible(find.text('To pay'), find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('₹850'), findsWidgets);
      expect(find.text('Includes GST ₹129.66'), findsOneWidget);
      expect(find.textContaining('Place order · ₹850'), findsOneWidget);

      await tester.dragUntilVisible(find.text('Change'), find.byType(ListView).first, const Offset(0, 200));
      await tester.pumpAndSettle();
      await tapIt(tester, find.text('Change'));
      await tapIt(tester, find.text('Sunita Patil'));
      expect(find.text('Sunita Patil'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
    });

    testWidgets('first order: the address form opens by itself, checks the details, saves', (tester) async {
      final api = signedInApi();
      await start(tester, api, saved: {...onboarded, 'nm_pincode': '421201'});
      await go(tester, '/checkout');
      expect(find.text('New address'), findsOneWidget);
      // name and mobile come from the account, pincode from Home
      expect(find.widgetWithText(TextFormField, 'Ravi Patil'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '9876543210'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '421201'), findsOneWidget);

      await tapIt(tester, find.text('Save and deliver here'));
      expect(find.text('Enter house no. and street'), findsOneWidget);
      expect(find.text('Enter a city name using letters only'), findsOneWidget);
      expect(api.requests.where((r) => r.method == 'POST' && r.path == '/users/me/addresses'), isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'House no., building, street'), 'Flat 12, Sai Darshan');
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Kalyan 123'); // digits are dropped
      await tapIt(tester, find.text('💼 Work'));
      await tapIt(tester, find.text('Save and deliver here'));
      final post = api.requests.lastWhere((r) => r.method == 'POST' && r.path == '/users/me/addresses').data as Map;
      expect(post['city'], 'Kalyan');
      expect(post['state'], 'Maharashtra');
      expect(post['postal_code'], '421201');
      expect(post['label'], 'Work');
      expect(post['is_default'], true);
      expect(find.text('New address'), findsNothing);
      expect(find.text('WORK'), findsOneWidget);
      expect(tester.widget<FilledButton>(placeButton).onPressed, isNotNull);
    });

    testWidgets('Place order sends the address and notes, then the pay screen shows', (tester) async {
      final api = signedInApi(addresses: [address(1, isDefault: true)]);
      await start(tester, api);
      await go(tester, '/checkout');
      await tester.enterText(find.widgetWithText(TextField, 'Delivery instructions (optional)'), '  Call before coming  ');
      await tapIt(tester, placeButton);
      final post = api.requests.lastWhere((r) => r.path == '/orders').data;
      expect(post, {'address_id': 1, 'notes': 'Call before coming'});

      expect(find.byType(OrderPlacedScreen), findsOneWidget);
      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('Order NM-482913'), findsOneWidget);
      expect(find.text('Pay ₹850 by UPI'), findsOneWidget);
      expect(find.text('Pay with UPI app'), findsOneWidget);

      // Back goes Home, never back into Checkout
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CheckoutScreen), findsNothing);
    });

    testWidgets('the server refuses (e.g. sold out): the reason shows, still on Checkout', (tester) async {
      await start(tester, signedInApi(addresses: [address(1, isDefault: true)], more: {
        'POST /orders': (_) => (400, {'detail': 'Only 2 left of Vacuum Cleaner'}),
      }));
      await go(tester, '/checkout');
      await tapIt(tester, placeButton);
      expect(find.text('Only 2 left of Vacuum Cleaner'), findsOneWidget);
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('stock problems block Place order', (tester) async {
      await start(tester, signedInApi(addresses: [address(1, isDefault: true)], more: {
        'GET /cart': (_) => (200, serverCart(qty: 3, stock: 1)),
      }));
      await go(tester, '/checkout');
      expect(find.text('Some items need attention before checkout'), findsOneWidget);
      expect(tester.widget<FilledButton>(placeButton).onPressed, isNull);
    });

    testWidgets('Marathi', (tester) async {
      await start(tester, signedInApi(addresses: [address(1, isDefault: true)]), saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
      await go(tester, '/checkout');
      expect(find.text('डिलिव्हरी पत्ता'), findsOneWidget);
      expect(find.textContaining('ऑर्डर द्या'), findsOneWidget);
    });
  });

  group('Pay after placing', () {
    testWidgets('UPI app link with the amount, copy UPI ID, WhatsApp proof with the UTR', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await start(tester, signedInApi());
      await go(tester, '/order/77/placed');
      expect(find.text('Pay ₹850 by UPI'), findsOneWidget);

      await tapIt(tester, find.text('Pay with UPI app'));
      final upi = Uri.parse(launcher.urls.last);
      expect(upi.scheme, 'upi');
      expect(upi.queryParameters, {'pa': 'vyapar.175693393199@hdfcbank', 'pn': 'NIRMAL MART', 'am': '850.00', 'cu': 'INR', 'tn': 'Order NM-482913'});

      await tapIt(tester, find.text('Copy UPI ID'));
      expect(copied.last, 'vyapar.175693393199@hdfcbank');
      expect(find.text('UPI ID copied'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'UPI reference / UTR no. (optional)'), '412345678901');
      await tapIt(tester, find.text('Send payment proof on WhatsApp'));
      final wa = Uri.parse(launcher.urls.last);
      expect(wa.host, 'wa.me');
      expect(wa.path, '/919022230687');
      expect(wa.queryParameters['text'], contains('Order ID: NM-482913'));
      expect(wa.queryParameters['text'], contains('Amount: ₹850'));
      expect(wa.queryParameters['text'], contains('UPI reference (UTR): 412345678901'));
    });

    testWidgets('no UPI app on the phone: says to use the QR', (tester) async {
      launcher.canOpen = false;
      await start(tester, signedInApi());
      await go(tester, '/order/77/placed');
      await tapIt(tester, find.text('Pay with UPI app'));
      expect(find.text('No UPI app found — scan or save the QR instead'), findsOneWidget);
    });

    testWidgets('already paid: no payment panel', (tester) async {
      await start(tester, signedInApi(more: {'GET /orders/77': (_) => (200, order(payment: 'paid'))}));
      await go(tester, '/order/77/placed');
      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('Pay with UPI app'), findsNothing);
    });
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
      await start(tester, signedInApi());
      await go(tester, '/checkout'); // no address yet: the form opens
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('New address'))).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await go(tester, '/order/77/placed');
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
