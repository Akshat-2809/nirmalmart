import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/wishlist/wishlist_screen.dart';

import 'helpers.dart';

Map<String, Object> saved(List<int> ids, {Map<int, num> oldPrices = const {}}) => {
      ...onboarded,
      'nm_guest_wishlist': jsonEncode([
        for (final id in ids) {...sampleProducts.firstWhere((p) => p['id'] == id), if (oldPrices[id] != null) 'price': oldPrices[id]},
      ]),
      'nm_wishlist_prices': jsonEncode({for (final e in oldPrices.entries) '${e.key}': e.value}),
    };

List<dynamic> wish(TestApp app) => jsonDecode(app.prefs.getString('nm_guest_wishlist') ?? '[]') as List;
List<dynamic> bag(TestApp app) => jsonDecode(app.prefs.getString('nm_guest_cart') ?? '[]') as List;

Future<void> openTab(WidgetTester tester) async {
  await tester.tap(find.text('Wishlist').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty: Explore products opens Shop', (tester) async {
    await startApp(tester, saved: onboarded);
    await openTab(tester);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    await tester.tap(find.text('Explore products'));
    await tester.pumpAndSettle();
    expect(find.byType(WishlistScreen), findsNothing);
  });

  testWidgets('guest: saved items, fresh prices, price drop, sign-in banner', (tester) async {
    // saved at ₹250, the Steel Bottle is ₹200 now
    await startApp(tester, saved: saved([4, 7], oldPrices: {4: 250}));
    await openTab(tester);
    expect(find.text('Steel Bottle'), findsOneWidget);
    expect(find.text('Lunch Box'), findsOneWidget);
    expect(find.textContaining('2 saved'), findsWidgets);
    expect(find.text('₹200'), findsWidgets);
    expect(find.text('1 item is cheaper than when you saved it'), findsOneWidget);
    expect(find.text('↓ Price dropped ₹50'), findsOneWidget);
    expect(find.text('Saved on this phone only. Sign in to keep it on every device.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sign in →'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Move to bag moves it off the wishlist', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await startApp(tester, saved: saved([4, 7]));
    await openTab(tester);
    await tester.tap(find.text('Move to bag').hitTestable().first);
    await tester.pumpAndSettle();
    expect(bag(app).single['product_id'], 4);
    expect(wish(app).map((p) => p['id']), [7]);
    expect(find.text('Moved to bag'), findsOneWidget);
  });

  testWidgets('remove with Undo', (tester) async {
    final app = await startApp(tester, saved: saved([4, 7]));
    await openTab(tester);
    await tester.tap(find.byTooltip('Remove from wishlist').first);
    await tester.pumpAndSettle();
    expect(wish(app).map((p) => p['id']), [7]);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(wish(app).map((p) => p['id']), [4, 7]);
  });

  testWidgets('sold out stays, without a bag button; Add all adds the rest', (tester) async {
    final app = await startApp(tester, saved: saved([3, 4, 7, 5])); // 3 = foot pump, sold out
    await openTab(tester);
    expect(find.text('Out of stock'), findsWidgets);
    expect(find.text('Add all to bag'), findsOneWidget);
    await tester.tap(find.text('Add all to bag'));
    await tester.pumpAndSettle();
    expect(bag(app).map((l) => l['product_id']).toSet(), {4, 7, 5});
    expect(find.text('3 items added to bag'), findsOneWidget);
    expect(find.text('In your bag'), findsWidgets);
    expect(find.text('Add all to bag'), findsNothing);
  });

  testWidgets('signed in: the account list from the server', (tester) async {
    final api = FakeApi({
      'GET /auth/me': (_) => (200, fakeUser()),
      'GET /cart': (_) => (200, {'items': [], 'total_items': 0, 'subtotal': 0, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 0, 'free_shipping_threshold': 499}),
      'GET /wishlist': (_) => (200, [sampleProducts[0]]),
      'DELETE /wishlist/*': (_) => (200, []),
    });
    await startApp(tester, saved: onboarded, tokens: MemoryTokens()..accessToken = 'acc', api: api);
    await openTab(tester);
    expect(find.text('Vacuum Cleaner'), findsOneWidget);
    expect(find.textContaining('Saved on this phone'), findsNothing);
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(api.requests.last.method, 'DELETE');
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('grid or list, remembered; list rows move to bag and remove', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await startApp(tester, saved: saved([4, 7], oldPrices: {4: 250}));
    await openTab(tester);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('nm_wishlist_view'), 'list');
    expect(find.text('↓ Price dropped ₹50'), findsOneWidget); // same details in the rows
    await tester.tap(find.text('Move to bag').first);
    await tester.pumpAndSettle();
    expect(bag(app).single['product_id'], 4);
    expect(wish(app).map((p) => p['id']), [7]);
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(wish(app), isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('nm_wishlist_view'), 'grid');
  });

  testWidgets('Marathi', (tester) async {
    await startApp(tester, saved: {...saved([4]), 'nm_locale': 'mr'});
    await tester.tap(find.text('विशलिस्ट').last);
    await tester.pumpAndSettle();
    expect(find.text('स्टील बाटली'), findsOneWidget);
    expect(find.text('बॅगमध्ये हलवा'), findsOneWidget);
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
      await startApp(tester, saved: saved([3, 4, 7, 5, 1], oldPrices: {4: 250}));
      await openTab(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('List view'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
