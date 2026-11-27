import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/catalog/models.dart';
import 'package:nirmal_mart/features/home/home_screen.dart';
import 'package:nirmal_mart/features/home/home_sections.dart';
import 'package:nirmal_mart/features/shop/shop_screen.dart';

import 'helpers.dart';

Finder get _scroll => find.byType(CustomScrollView);

/// Scrolls Home down until [f] is built, then brings the first match on screen
Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 60 && f.evaluate().isEmpty; i++) {
    await tester.drag(_scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  await Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5); // mid-screen, clear of the slim search bar
  await tester.pumpAndSettle();
}

List<dynamic> _savedCart(TestApp app) => jsonDecode(app.prefs.getString('nm_guest_cart') ?? '[]') as List;

void main() {
  group('Home', () {
    testWidgets('greets a guest and shows every section from the catalogue', (tester) async {
      await startApp(tester, saved: onboarded);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.textContaining('Add pincode', findRichText: true), findsOneWidget);
      expect(find.text('Under ₹999'), findsOneWidget); // first offer card
      expect(find.text('Shop by category'), findsOneWidget);
      expect(find.text('Car & Bike Care'), findsWidgets);

      // Deal of the day = biggest in-stock discount (Vacuum Cleaner, 52% off)
      await _scrollTo(tester, find.text('DEAL OF THE DAY'));
      expect(find.text('Ends in'), findsOneWidget);
      expect(find.text('🔥 Only 10 left'), findsOneWidget);
      expect(find.text('Vacuum Cleaner'), findsWidgets);
      expect(find.text('52% OFF'), findsWidgets);

      for (final title in ['More deals for today', 'Shop by budget', '🔥 Trending now', 'Just for you', 'Made with ❤️ in Maharashtra']) {
        await _scrollTo(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('greets a signed-in shopper by first name', (tester) async {
      final tokens = MemoryTokens()..accessToken = 'acc';
      await startApp(tester,
          saved: onboarded,
          tokens: tokens,
          api: FakeApi({
            'GET /auth/me': (_) => (200, fakeUser()),
            'GET /cart': (_) => (200, {'items': [], 'total_items': 0, 'subtotal': 0, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 0, 'free_shipping_threshold': 499}),
            'GET /wishlist': (_) => (200, []),
          }));
      expect(find.text('Hello, Ravi'), findsOneWidget);
    });

    testWidgets('ADD puts it in the bag, then – 1 + changes the quantity', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await _scrollTo(tester, find.text('More deals for today'));
      await tester.tap(find.text('ADD').hitTestable().first);
      await tester.pumpAndSettle();

      expect(_savedCart(app), hasLength(1));
      expect(_savedCart(app).first['quantity'], 1);
      expect(find.text('Added to bag'), findsOneWidget);
      expect(find.byTooltip('Bag, 1'), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsWidgets); // now a stepper
      // Under ₹499 → the free-delivery bar says how much more
      final added = _savedCart(app).first['product_price'] as num;
      if (added < 499) expect(find.textContaining('more for FREE delivery'), findsOneWidget);

      // the free-delivery bar took some room at the bottom, so bring the stepper back into view
      await _scrollTo(tester, find.bySemanticsLabel('Add one more'));
      await tester.tap(find.bySemanticsLabel('Add one more').hitTestable().first);
      await tester.pumpAndSettle();
      expect(_savedCart(app).first['quantity'], 2);

      await tester.tap(find.bySemanticsLabel('Remove one').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove one').hitTestable().first);
      await tester.pumpAndSettle();
      expect(_savedCart(app), isEmpty);
      expect(find.byTooltip('Bag'), findsOneWidget);
      expect(find.textContaining('more for FREE delivery'), findsNothing);
    });

    testWidgets('signed-in ADD goes to the server cart', (tester) async {
      final tokens = MemoryTokens()..accessToken = 'acc';
      Map<String, Object?> cart(int qty) => {
            'items': [
              if (qty > 0)
                {'id': 51, 'product_id': 1, 'product_name': 'Vacuum Cleaner', 'product_slug': 'vacuum-cleaner', 'product_price': 1000, 'compare_at_price': 2100, 'product_image': null, 'stock_quantity': 10, 'quantity': qty, 'subtotal': 1000 * qty},
            ],
            'total_items': qty,
            'subtotal': 1000 * qty,
            'tax_amount': 0,
            'shipping_amount': 0,
            'total_amount': 1000 * qty,
            'free_shipping_threshold': 499,
          };
      final api = FakeApi({
        'GET /auth/me': (_) => (200, fakeUser()),
        'GET /cart': (_) => (200, cart(0)),
        'GET /wishlist': (_) => (200, []),
        'POST /cart/items': (_) => (200, cart(1)),
      });
      await startApp(tester, saved: onboarded, tokens: tokens, api: api);
      await _scrollTo(tester, find.text('DEAL OF THE DAY'));
      await _scrollTo(tester, find.text('More deals for today'));
      await tester.tap(find.text('ADD').hitTestable().first);
      await tester.pumpAndSettle();
      final post = api.requests.lastWhere((r) => r.path == '/cart/items');
      expect((post.data as Map)['quantity'], 1);
      expect(find.byTooltip('Bag, 1'), findsOneWidget);
      expect(find.textContaining('FREE delivery'), findsNothing); // ₹1,000 is over ₹499
    });

    testWidgets('the heart saves to the wishlist on the phone', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await _scrollTo(tester, find.text('More deals for today'));
      await tester.tap(find.byTooltip('Save to wishlist').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Saved to wishlist'), findsOneWidget);
      expect(jsonDecode(app.prefs.getString('nm_guest_wishlist')!) as List, hasLength(1));
      expect(find.byTooltip('Remove from wishlist'), findsWidgets);
    });

    testWidgets('pincode check shows a delivery date and is remembered', (tester) async {
      final app = await startApp(tester, saved: onboarded, api: FakeApi({
        'GET /shipping/estimate': (_) => (200, {'available': true, 'serviceable': true, 'min_days': 3, 'max_days': 5, 'cod': false}),
      }));
      await tester.tap(find.textContaining('Add pincode', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('Where should we deliver?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 6-digit pincode'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '421201');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Delivery by'), findsOneWidget);
      expect(app.prefs.getString('nm_pincode'), '421201');
      expect(find.textContaining('421201', findRichText: true), findsWidgets); // header behind the sheet
    });

    testWidgets('says so when a pincode is not served', (tester) async {
      await startApp(tester, saved: onboarded, api: FakeApi({
        'GET /shipping/estimate': (_) => (200, {'available': true, 'serviceable': false}),
      }));
      await tester.tap(find.textContaining('Add pincode', findRichText: true));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '799001');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('Sorry, we don’t deliver to this pincode yet'), findsOneWidget);
    });

    testWidgets('offline: friendly error, then Try again loads the shop', (tester) async {
      var down = true;
      final routes = catalogueRoutes();
      final api = FakeApi({
        'GET /products': (o) => down ? (503, {'detail': 'down'}) : routes['GET /products']!(o),
      });
      await startApp(tester, saved: onboarded, api: api);
      expect(find.text('Couldn’t load the shop'), findsOneWidget);
      down = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load the shop'), findsNothing);
      expect(find.text('Shop by category'), findsOneWidget);
    });

    testWidgets('no offer cards when the owner hides the banner', (tester) async {
      await startApp(tester, saved: onboarded, api: FakeApi(catalogueRoutes(showBanner: false)));
      expect(find.byType(PromoCarousel), findsNothing);
      expect(find.text('Shop by category'), findsOneWidget);
    });

    testWidgets('a category tile opens Shop', (tester) async {
      await startApp(tester, saved: onboarded);
      await _scrollTo(tester, find.text('Tools & Outdoor'));
      await tester.tap(find.text('Tools & Outdoor').first);
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget); // the Shop tab, on that category
      expect(find.textContaining('2 products'), findsWidgets);
    });

    testWidgets('scrolling down brings in the slim search bar', (tester) async {
      await startApp(tester, saved: onboarded);
      expect(find.byTooltip('Bag'), findsNWidgets(2)); // header + the hidden slim bar
      await tester.drag(_scroll, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Search Nirmal Mart'), findsOneWidget); // slim bar's hint
      expect(tester.takeException(), isNull);
    });

    testWidgets('Marathi', (tester) async {
      await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
      expect(find.text('नमस्कार'), findsOneWidget);
      expect(find.text('विभागानुसार खरेदी'), findsOneWidget);
      expect(find.text('कार आणि बाईक केअर'), findsWidgets); // category names from the API
    });

    for (final dark in [false, true]) {
      testWidgets('small phone with large text${dark ? ', dark mode' : ''}: no overflow anywhere', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await startApp(tester, saved: onboarded);
        await _scrollTo(tester, find.text('ADD'));
        await tester.tap(find.text('ADD').hitTestable().first);
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text('Made with ❤️ in Maharashtra'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('loading shows placeholders, and animations run cleanly', (tester) async {
      await startApp(tester, saved: onboarded, animate: true, live: true);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Shop by category'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox()); // stop the countdown and carousel timers
    });
  });

  test('countdown runs to midnight', () {
    expect(untilMidnight(DateTime(2026, 11, 25, 18, 47, 27)), (5, 12, 33));
    expect(untilMidnight(DateTime(2026, 11, 25, 23, 59, 59)), (0, 0, 1));
  });

  test('Just for you mixes categories, keeps everything, and stays the same all day', () {
    final all = [for (final p in sampleProducts) Product.fromJson(p)];
    final a = mixProducts(all, today: DateTime(2026, 11, 25, 9));
    final b = mixProducts(all, today: DateTime(2026, 11, 25, 21));
    expect(a.map((p) => p.id), b.map((p) => p.id));
    expect(a.map((p) => p.id).toSet(), all.map((p) => p.id).toSet());
    expect(a.take(3).map((p) => p.categoryId).toSet(), hasLength(3)); // first round: one from each category
  });
}
