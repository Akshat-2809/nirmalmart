import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/product/product_screen.dart';
import 'package:nirmal_mart/features/product/product_sections.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';

import 'helpers.dart';

/// Opens a product page the way a link would (no card data passed along)
Future<void> openPage(WidgetTester tester, String slug) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push('/product/$slug');
  await tester.pumpAndSettle();
}

Finder get _page => find.descendant(of: find.byType(ProductScreen), matching: find.byType(CustomScrollView));

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    await tester.drag(_page, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  await Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

List<dynamic> savedCart(TestApp app) => jsonDecode(app.prefs.getString('nm_guest_cart') ?? '[]') as List;

Finder bottomButton(String text) => find.descendant(
      of: find.byType(ProductScreen),
      matching: find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
    );

void main() {
  group('Product page', () {
    testWidgets('opens from a Home card with everything on it', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await tester.dragUntilVisible(find.text('More deals for today'), find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Steel Bottle').hitTestable().first);
      await tester.pumpAndSettle();

      expect(find.byType(ProductScreen), findsOneWidget);
      expect(find.text('Steel Bottle'), findsWidgets);
      expect(find.text('स्टील बाटली'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('50% OFF'), findsOneWidget);
      expect(find.text('⚡ Top deal'), findsOneWidget);
      expect(find.text('HOME & KITCHEN'), findsOneWidget); // category chip
      expect(find.textContaining('Save ₹200', findRichText: true), findsOneWidget);
      expect(find.text('🔥 Hurry — only 10 left'), findsOneWidget); // 10 or fewer
      expect(find.text('Quantity'), findsOneWidget);
      expect(bottomButton('Add to bag'), findsOneWidget);
      expect(bottomButton('Buy now'), findsOneWidget);
      expect(app.prefs.getStringList('nm_recent'), ['4']); // remembered for Recently viewed

      await scrollTo(tester, find.text('About this product'));
      expect(find.text('All about Steel Bottle.'), findsOneWidget);
      expect(find.text('Highlights'), findsNothing); // none filled in → hidden
      await scrollTo(tester, find.text('No reviews yet'));
      expect(find.text('Sign in to review'), findsOneWidget);
      await scrollTo(tester, find.text('You may also like'));
      expect(find.text('Vegetable Chopper'), findsWidgets); // same category
      expect(tester.takeException(), isNull);
    });

    testWidgets('quantity, Add to bag, then Go to bag', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await openPage(tester, 'lunch-box');
      await scrollTo(tester, find.text('Quantity'));
      await tester.tap(find.byTooltip('Add one more'));
      await tester.pump();
      await tester.tap(find.byTooltip('Add one more'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(QuantityRow), matching: find.text('3')), findsOneWidget);

      await tester.tap(bottomButton('Add to bag'));
      await tester.pumpAndSettle();
      expect(savedCart(app).single['quantity'], 3);
      expect(find.text('Added to bag'), findsOneWidget);
      expect(bottomButton('Go to bag'), findsOneWidget);
      expect(find.byTooltip('Bag, 3'), findsOneWidget);

      await tester.tap(bottomButton('Go to bag'));
      await tester.pumpAndSettle();
      expect(find.text('My bag'), findsOneWidget);
    });

    testWidgets('quantity stops at the stock', (tester) async {
      await startApp(tester, saved: onboarded, api: FakeApi(catalogueRoutes(products: [fakeProduct(1, 'Last Two', price: 300, stock: 2)])));
      await openPage(tester, 'last-two');
      expect(find.text('🔥 Hurry — only 2 left'), findsOneWidget);
      await scrollTo(tester, find.text('Quantity'));
      await tester.tap(find.byTooltip('Add one more'));
      await tester.pumpAndSettle();
      final plus = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded).last);
      expect(plus.onPressed, isNull);
    });

    testWidgets('Buy now puts it in the bag and asks a guest to sign in for Checkout', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await openPage(tester, 'spice-rack');
      await tester.tap(bottomButton('Buy now'));
      await tester.pumpAndSettle();
      expect(savedCart(app).single['product_id'], 6);
      // a guest signs in first, then goes on to Checkout
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).from, '/checkout');
    });

    testWidgets('out of stock: no quantity, no buttons to buy', (tester) async {
      await startApp(tester, saved: onboarded);
      await openPage(tester, 'mini-foot-pump');
      expect(find.text('Out of stock'), findsWidgets);
      expect(find.text('Quantity'), findsNothing);
      expect(bottomButton('Add to bag'), findsNothing);
      expect(bottomButton('Buy now'), findsNothing);
    });

    testWidgets('description switches to Marathi', (tester) async {
      await startApp(tester, saved: onboarded);
      await openPage(tester, 'lunch-box');
      await scrollTo(tester, find.text('About this product'));
      await tester.tap(find.text('मराठी'));
      await tester.pumpAndSettle();
      expect(find.text('डबा बद्दल माहिती.'), findsOneWidget);
      expect(find.text('All about Lunch Box.'), findsNothing);
    });

    testWidgets('shows the delivery date for the saved pincode', (tester) async {
      await startApp(tester, saved: {...onboarded, 'nm_pincode': '421201'}, api: FakeApi({
        'GET /shipping/estimate': (_) => (200, {'available': true, 'serviceable': true, 'min_days': 3}),
      }));
      await openPage(tester, 'lunch-box');
      await scrollTo(tester, find.text('Delivering to 421201'));
      expect(find.textContaining('Get it by', findRichText: true), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('heart saves it, and the page has a share button', (tester) async {
      final shared = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (call) async {
        shared.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), null));
      final app = await startApp(tester, saved: onboarded);
      await openPage(tester, 'lunch-box');
      await tester.tap(find.byTooltip('Save to wishlist'));
      await tester.pumpAndSettle();
      expect(jsonDecode(app.prefs.getString('nm_guest_wishlist')!) as List, hasLength(1));
      expect(find.byTooltip('Remove from wishlist'), findsOneWidget);

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(shared, isNotEmpty);
      expect('${shared.first.arguments}', contains('https://www.nirmalmart.in/product/lunch-box'));
    });

    testWidgets('reviews: summary, verified badge, and writing one', (tester) async {
      final tokens = MemoryTokens()..accessToken = 'acc';
      final api = FakeApi({
        'GET /auth/me': (_) => (200, fakeUser()),
        'GET /cart': (_) => (200, {'items': [], 'total_items': 0, 'subtotal': 0, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 0, 'free_shipping_threshold': 499}),
        'GET /wishlist': (_) => (200, []),
        'GET /products/*/reviews': (_) => (200, {
              'average': 4.5,
              'count': 2,
              'distribution': {'1': 0, '2': 0, '3': 0, '4': 1, '5': 1},
              'reviews': [
                {'id': 1, 'user_id': 3, 'user_name': 'Sunita', 'product_id': 1, 'rating': 5, 'title': 'Superb', 'comment': 'Works great', 'is_verified_purchase': true, 'created_at': '2026-11-20T10:00:00Z'},
                {'id': 2, 'user_id': 4, 'user_name': 'Amol', 'product_id': 1, 'rating': 4, 'title': null, 'comment': 'Good value', 'is_verified_purchase': false, 'created_at': '2026-11-21T10:00:00Z'},
              ],
              'can_review': true,
            }),
        'POST /products/*/reviews': (_) => (201, {'id': 3}),
      });
      await startApp(tester, saved: onboarded, tokens: tokens, api: api);
      await openPage(tester, 'vacuum-cleaner');
      expect(find.text('12 reviews'), findsOneWidget); // from the product (rating_count)
      await scrollTo(tester, find.text('Ratings & reviews'));
      expect(find.text('4.5'), findsWidgets);
      await scrollTo(tester, find.text('Superb'));
      expect(find.text('Verified purchase'), findsOneWidget);
      expect(find.text('Good value'), findsOneWidget);

      await scrollTo(tester, find.text('Write a review'));
      await tester.tap(find.text('Write a review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post review'));
      await tester.pumpAndSettle();
      expect(find.text('Please choose a star rating'), findsOneWidget);
      await tester.tap(find.byTooltip('Very good'));
      await tester.enterText(find.widgetWithText(TextField, 'Your review (optional)'), '  Sucks up everything  ');
      await tester.tap(find.text('Post review'));
      await tester.pumpAndSettle();
      final post = api.requests.lastWhere((r) => r.method == 'POST' && r.path.endsWith('/reviews'));
      expect(post.path, '/products/1/reviews');
      expect(post.data, {'rating': 4, 'comment': 'Sucks up everything'});
      expect(find.text('Thanks for your review!'), findsOneWidget);
    });

    testWidgets('a removed product says so and goes back to shopping', (tester) async {
      await startApp(tester, saved: onboarded);
      await openPage(tester, 'gone-forever');
      expect(find.text('This product isn’t available'), findsOneWidget);
      await tester.tap(find.text('Back to shopping'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductScreen), findsNothing);
    });

    testWidgets('offline: Try again loads it', (tester) async {
      var down = true;
      final routes = catalogueRoutes();
      await startApp(tester, saved: onboarded, api: FakeApi({
        'GET /products/*': (o) => down ? (503, {'detail': 'down'}) : routes['GET /products/*']!(o),
      }));
      await openPage(tester, 'lunch-box');
      expect(find.text('Couldn’t load the shop'), findsOneWidget);
      down = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Lunch Box'), findsWidgets);
    });

    testWidgets('Marathi page', (tester) async {
      await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
      await openPage(tester, 'lunch-box');
      expect(find.text('डबा'), findsWidgets);
      expect(bottomButton('बॅगमध्ये जोडा'), findsOneWidget);
      expect(bottomButton('आता खरेदी करा'), findsOneWidget);
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
        await startApp(tester, saved: {...onboarded, 'nm_pincode': '421201'});
        await openPage(tester, 'vacuum-cleaner');
        await scrollTo(tester, find.text('You may also like'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('animations run cleanly (add flies to the bag)', (tester) async {
      await startApp(tester, saved: onboarded, animate: true);
      await openPage(tester, 'lunch-box');
      await tester.tap(bottomButton('Add to bag'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(bottomButton('Go to bag'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3)); // snackbar timer
    });
  });
}
