import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/bag/bag_screen.dart';
import 'package:nirmal_mart/features/shop/shop_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';

import 'helpers.dart';

/// A guest bag line saved on the phone, from a sample product (optionally with an old price)
Map<String, Object?> line(int id, int qty, {num? price, int? stock}) {
  final p = [...sampleProducts, ...extra].firstWhere((p) => p['id'] == id);
  return {
    'id': 'g-$id',
    'product_id': id,
    'product_name': p['name'],
    'product_name_mr': p['name_mr'],
    'product_slug': p['slug'],
    'product_price': price ?? p['price'],
    'compare_at_price': p['compare_at_price'],
    'product_image': null,
    'stock_quantity': stock ?? p['stock_quantity'],
    'quantity': qty,
  };
}

final extra = [fakeProduct(40, 'Last Two Lamps', price: 300, mrp: 400, stock: 2)];

Map<String, Object> bag(List<Map<String, Object?>> lines) => {...onboarded, 'nm_guest_cart': jsonEncode(lines)};

List<dynamic> saved(TestApp app) => jsonDecode(app.prefs.getString('nm_guest_cart') ?? '[]') as List;

Future<void> openBag(WidgetTester tester) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push('/bag');
  await tester.pumpAndSettle();
}

Future<void> tapIt(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Finder get list => find.descendant(of: find.byType(BagScreen), matching: find.byType(Scrollable)).first;

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 20 && f.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
}

FakeApi api() => FakeApi(catalogueRoutes(products: [...sampleProducts, ...extra]));

void main() {
  group('Bag', () {
    testWidgets('empty: Start shopping, wishlist reminder, popular picks', (tester) async {
      await startApp(tester, saved: {...onboarded, 'nm_guest_wishlist': jsonEncode([sampleProducts[0]])});
      await openBag(tester);
      expect(find.text('Your bag is empty'), findsOneWidget);
      expect(find.text('तुमची बॅग रिकामी आहे'), findsOneWidget);
      expect(find.text('1 item in your wishlist'), findsOneWidget);
      expect(find.text('🔥 Popular right now'), findsOneWidget);
      expect(find.text('Checkout'), findsNothing);
      await tapIt(tester, find.text('Start shopping'));
      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('items, free-delivery progress, price details and the total', (tester) async {
      await startApp(tester, saved: bag([line(4, 1), line(7, 1)]), api: api()); // ₹200 + ₹350 = ₹550
      await openBag(tester);
      expect(find.text('Steel Bottle'), findsOneWidget);
      expect(find.text('Lunch Box'), findsOneWidget);
      expect(find.text('2 items · माझी बॅग'), findsOneWidget);
      expect(find.text('Yay! You get FREE delivery on this order'), findsOneWidget);
      await scrollTo(tester, find.text('Price details'));
      expect(find.text('MRP (2 items)'), findsOneWidget);
      expect(find.text('₹780'), findsOneWidget); // ₹400 + ₹380
      expect(find.text('−₹230'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('₹550'), findsWidgets); // total, also in the bottom bar
      expect(find.text('Includes GST ₹83.90'), findsOneWidget);
      expect(find.text('🎉 You’re saving ₹230 on this order'), findsOneWidget);
    });

    testWidgets('under ₹499: delivery fee, how much more, and products that get you there', (tester) async {
      await startApp(tester, saved: bag([line(4, 1)]), api: api()); // ₹200
      await openBag(tester);
      expect(find.textContaining('Add ₹299 more for FREE delivery', findRichText: true), findsOneWidget);
      await scrollTo(tester, find.text('Add ₹299 more for free delivery'));
      // ₹299 or more each, cheapest first, not already in the bag
      expect(find.text('Vegetable Chopper'), findsWidgets);
      await scrollTo(tester, find.text('Price details'));
      expect(find.text('₹49'), findsOneWidget);
      expect(find.text('₹249'), findsWidgets);
    });

    testWidgets('fresh prices from the server when it opens', (tester) async {
      final app = await startApp(tester, saved: bag([line(4, 1, price: 150)]), api: api());
      await openBag(tester);
      expect(find.text('₹200'), findsWidgets); // the old ₹150 was replaced
      expect(saved(app).single['product_price'], 200);
    });

    testWidgets('quantity, remove at 1 with Undo', (tester) async {
      final app = await startApp(tester, saved: bag([line(4, 1), line(7, 1)]), api: api());
      await openBag(tester);
      await tester.tap(find.byTooltip('Add one more').first);
      await tester.pumpAndSettle();
      expect(saved(app).first['quantity'], 2);
      await tester.tap(find.byTooltip('Remove one').first);
      await tester.pumpAndSettle();
      expect(saved(app).first['quantity'], 1);

      await tester.tap(find.byTooltip('Remove').first); // the bin at 1
      await tester.pumpAndSettle();
      expect(saved(app), hasLength(1));
      expect(find.text('Removed from bag'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(saved(app).map((l) => l['product_id']), [4, 7]); // back in its place
    });

    testWidgets('swipe left removes', (tester) async {
      final app = await startApp(tester, saved: bag([line(4, 1), line(7, 1)]), api: api());
      await openBag(tester);
      await tester.drag(find.text('Steel Bottle'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(saved(app).map((l) => l['product_id']), [7]);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('move to wishlist', (tester) async {
      final app = await startApp(tester, saved: bag([line(4, 1)]), api: api());
      await openBag(tester);
      await tapIt(tester, find.byTooltip('Move to wishlist'));
      expect(find.text('Moved to wishlist'), findsOneWidget);
      expect(saved(app), isEmpty);
      expect((jsonDecode(app.prefs.getString('nm_guest_wishlist')!) as List).single['id'], 4);
      expect(find.text('Your bag is empty'), findsOneWidget);
    });

    testWidgets('more in the bag than in stock: warning, Checkout blocked until fixed', (tester) async {
      final app = await startApp(tester, saved: bag([line(40, 5)]), api: api());
      await openBag(tester);
      expect(find.text('Only 2 left — reduce the quantity'), findsOneWidget);
      expect(find.text('Some items need attention before checkout'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout')).onPressed, isNull);
      await tapIt(tester, find.text("Set to what's left"));
      expect(saved(app).single['quantity'], 2);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout')).onPressed, isNotNull);
    });

    testWidgets('sold out: remove it to continue', (tester) async {
      final app = await startApp(tester, saved: bag([line(3, 1), line(4, 1)]), api: api()); // the foot pump is sold out
      await openBag(tester);
      expect(find.text('Out of stock — remove it to continue'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout')).onPressed, isNull);
      await tapIt(tester, find.widgetWithText(OutlinedButton, 'Remove'));
      expect(saved(app).map((l) => l['product_id']), [4]);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout')).onPressed, isNotNull);
    });

    testWidgets('a guest is asked to sign in before checkout', (tester) async {
      await startApp(tester, saved: bag([line(4, 1)]), api: api());
      await openBag(tester);
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).from, '/checkout');
    });

    testWidgets('signed in: the bag comes from the account; changes go to the server; Checkout opens', (tester) async {
      Map<String, Object?> cart(int qty) => {
            'items': [
              {'id': 51, 'product_id': 1, 'product_name': 'Vacuum Cleaner', 'product_name_mr': 'व्हॅक्यूम क्लीनर', 'product_slug': 'vacuum-cleaner', 'product_price': 1000, 'compare_at_price': 2100, 'product_image': null, 'stock_quantity': 10, 'quantity': qty, 'subtotal': 1000 * qty},
            ],
            'total_items': qty,
            'subtotal': 1000 * qty,
            'tax_amount': 152.54 * qty,
            'shipping_amount': 0,
            'total_amount': 1000 * qty,
            'free_shipping_threshold': 499,
          };
      final fake = FakeApi({
        'GET /auth/me': (_) => (200, fakeUser()),
        'GET /cart': (_) => (200, cart(1)),
        'GET /wishlist': (_) => (200, []),
        'PUT /cart/items/51': (o) => (200, cart((o.data as Map)['quantity'] as int)),
      });
      await startApp(tester, saved: onboarded, tokens: MemoryTokens()..accessToken = 'acc', api: fake);
      await openBag(tester);
      expect(find.text('Vacuum Cleaner'), findsOneWidget);
      await tester.tap(find.byTooltip('Add one more').first);
      await tester.pumpAndSettle();
      expect(fake.requests.last.path, '/cart/items/51');
      expect(fake.requests.last.data, {'quantity': 2});
      expect(find.text('₹2,000'), findsWidgets);
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      expect(find.text('Checkout'), findsWidgets); // the Checkout screen (placeholder for now)
      expect(find.byType(BagScreen), findsNothing);
    });

    testWidgets('View details jumps to the price breakdown', (tester) async {
      await startApp(tester, saved: bag([line(4, 1), line(7, 1), line(5, 1), line(6, 1)]), api: api());
      await openBag(tester);
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.text('Price details').hitTestable(), findsOneWidget);
    });

    testWidgets('Marathi', (tester) async {
      await startApp(tester, saved: {...bag([line(4, 1)]), 'nm_locale': 'mr'}, api: api());
      await openBag(tester);
      expect(find.text('माझी बॅग'), findsOneWidget);
      expect(find.text('स्टील बाटली'), findsOneWidget); // Marathi name first
      expect(find.text('चेकआउट'), findsOneWidget);
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
        await startApp(tester, saved: {...bag([line(40, 5), line(3, 1), line(4, 1)]), 'nm_pincode': '421201'}, api: api());
        await openBag(tester);
        await scrollTo(tester, find.text('Price details'));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
