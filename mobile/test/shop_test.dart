import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/catalog/shop.dart';
import 'package:nirmal_mart/features/shop/shop_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:nirmal_mart/shared/product_card.dart';

import 'helpers.dart';

Future<void> goShop(WidgetTester tester, [String path = '/shop']) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

Map<String, dynamic> lastList(TestApp app) => app.api.requests.lastWhere((r) => r.path == '/products' && r.queryParameters['per_page'] == shopPageSize).queryParameters;

List<String> names(WidgetTester tester) => [
      for (final c in tester.widgetList<ProductCard>(find.byType(ProductCard))) c.product.name,
      for (final c in tester.widgetList<ProductListTile>(find.byType(ProductListTile))) c.product.name,
    ];

/// Scrolls [f] into view (pill rows, sheets and lists scroll) and taps it
Future<void> tapIt(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Finder pill(String label) => find.descendant(of: find.byType(ShopScreen), matching: find.text(label)).first;

void main() {
  test('Shop filters read the same links as the website', () {
    final f = ShopFilters.fromQuery({
      'category': ['car-bike'],
      'sort_by': ['discount'],
      'max_price': ['999'],
      'in_stock': ['true'],
      'brand': ['MZ', 'LED'],
    });
    expect(f.category, 'car-bike');
    expect(f.sort, ShopSort.discount);
    expect(f.maxPrice, 999);
    expect(f.count, 4); // in stock + price + 2 brands
    expect(f.query(page: 2, perPage: 24), containsPair('brand', ['LED', 'MZ']));
    expect(ShopFilters.fromQuery({'trending': ['true']}).trending, isTrue);
    expect(f.cleared(), const ShopFilters(category: 'car-bike', sort: ShopSort.discount));
  });

  group('Shop tab', () {
    testWidgets('shows everything with category pills and the toolbar', (tester) async {
      await startApp(tester, saved: onboarded);
      await tester.tap(find.text('Shop').last);
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget);
      expect(find.textContaining('9 products'), findsWidgets);
      for (final t in ['All', 'Trending', 'Home & Kitchen', 'Filters', 'Newest', 'In stock', 'Under ₹499']) {
        expect(find.descendant(of: find.byType(ShopScreen), matching: find.text(t)), findsWidgets, reason: t);
      }
      expect(names(tester), isNotEmpty);
    });

    testWidgets('a category pill shows just that category', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester);
      await tapIt(tester, pill('Car & Bike Care'));
      expect(lastList(app)['category'], 'car-bike');
      expect(find.textContaining('3 products'), findsWidgets);
      expect(find.textContaining('कार आणि बाईक केअर'), findsOneWidget); // subtitle in the other language

      await tapIt(tester, pill('Trending'));
      expect(lastList(app)['trending'], true);
      expect(lastList(app).containsKey('category'), isFalse);
      expect(find.textContaining('3 products'), findsWidgets);
      expect(names(tester), contains('Vacuum Cleaner'));
    });

    testWidgets('quick chips, removable filter chips, Clear all', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester);
      await tapIt(tester, pill('In stock'));
      expect(lastList(app)['in_stock'], true);
      expect(find.textContaining('8 products'), findsWidgets); // the foot pump is sold out
      await tapIt(tester, pill('Under ₹499'));
      expect(lastList(app)['max_price'], 499);
      expect(find.bySemanticsLabel('Remove filter In stock'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove filter Under ₹499'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Remove filter In stock'));
      await tester.pumpAndSettle();
      expect(lastList(app).containsKey('in_stock'), isFalse);
      await tapIt(tester, find.text('Clear all'));
      expect(find.textContaining('9 products'), findsWidgets);
    });

    testWidgets('sort sheet', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester);
      await tapIt(tester, pill('Newest'));
      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();
      expect(lastList(app)['sort_by'], 'price_low');
      expect(names(tester).first, 'Steel Bottle'); // ₹200, the cheapest
    });

    testWidgets('filters sheet: category, brand, price, live count, apply', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester);
      await tapIt(tester, pill('Filters'));
      expect(find.text('Show 9 products'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Tools & Outdoor')));
      await tester.pumpAndSettle();
      expect(find.text('Show 2 products'), findsOneWidget);
      await tapIt(tester, find.text('MZ')); // brands come from that category
      expect(find.text('Show 1 product'), findsOneWidget);
      await tester.tap(find.text('Under ₹199'));
      await tester.pumpAndSettle();
      expect(find.text('No products match'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'No products match')).onPressed, isNull);
      await tester.tap(find.text('Under ₹199'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show 1 product'));
      await tester.pumpAndSettle();
      expect(lastList(app)['category'], 'tools-outdoor');
      expect(lastList(app)['brand'], ['MZ']);
      expect(names(tester), ['Garden Sprayer']);
      expect(find.bySemanticsLabel('Remove filter MZ'), findsOneWidget);
      expect(find.descendant(of: find.byType(ShopScreen), matching: find.text('1')), findsOneWidget); // on the Filters button
    });

    testWidgets('links from Home open already filtered', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester, '/shop?category=home-kitchen&sort_by=discount&max_price=999');
      expect(lastList(app)['category'], 'home-kitchen');
      expect(lastList(app)['sort_by'], 'discount');
      expect(find.text('Home & Kitchen'), findsWidgets);
      expect(find.text('Biggest discount'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove filter Under ₹999'), findsOneWidget);
      expect(names(tester).first, 'Steel Bottle'); // 50% off
    });

    testWidgets('nothing matches → Clear filters', (tester) async {
      await startApp(tester, saved: onboarded);
      await goShop(tester, '/shop?max_price=10');
      expect(find.text('Nothing matches these filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.textContaining('9 products'), findsWidgets);
    });

    testWidgets('grid or list, remembered', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await goShop(tester);
      expect(find.byType(ProductListTile), findsNothing);
      await tester.tap(find.byTooltip('List view'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductListTile), findsWidgets);
      expect(find.byType(ProductCard), findsNothing);
      expect(app.prefs.getString('nm_shop_view'), 'list');
      // ADD works from the list too
      await tester.tap(find.text('ADD').first);
      await tester.pumpAndSettle();
      expect(find.text('Added to bag'), findsOneWidget);
    });

    testWidgets('more products load as you scroll, and ↑ goes back to the top', (tester) async {
      final many = [for (var i = 1; i <= 60; i++) fakeProduct(i, 'Item $i', price: 100 + i)];
      final app = await startApp(tester, saved: onboarded, api: FakeApi(catalogueRoutes(products: many)));
      await goShop(tester);
      expect(find.textContaining('60 products'), findsWidgets);
      for (var i = 0; i < 40 && !app.api.requests.any((r) => r.queryParameters['page'] == 3); i++) {
        await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -900));
        await tester.pumpAndSettle();
      }
      expect(app.api.requests.where((r) => r.path == '/products').map((r) => r.queryParameters['page']), containsAll([1, 2, 3]));
      await tester.tap(find.byTooltip('Back to top'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back to top').hitTestable(), findsNothing);
    });

    testWidgets('offline → Try again', (tester) async {
      var down = true;
      final routes = catalogueRoutes();
      await startApp(tester, saved: onboarded, api: FakeApi({
        'GET /products': (o) => down && o.queryParameters['per_page'] == shopPageSize ? (503, {'detail': 'down'}) : routes['GET /products']!(o),
      }));
      await goShop(tester);
      expect(find.text('Couldn’t load the shop'), findsOneWidget);
      down = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('9 products'), findsWidgets);
    });

    testWidgets('Marathi', (tester) async {
      await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
      await goShop(tester, '/shop?category=car-bike');
      expect(find.text('कार आणि बाईक केअर'), findsWidgets);
      expect(find.textContaining('3 उत्पादने'), findsWidgets);
      expect(find.text('फिल्टर'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('small phone with large text${dark ? ', dark' : ''}: no overflow, sheets too', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await startApp(tester, saved: {...onboarded, 'nm_shop_view': 'list'});
        await goShop(tester, '/shop?in_stock=true&min_price=100&max_price=1500');
        expect(tester.takeException(), isNull);
        await tapIt(tester, pill('Filters'));
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(BottomSheet))).pop(); // close
        await tester.pumpAndSettle();
        await tapIt(tester, find.byTooltip('Grid view'));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
