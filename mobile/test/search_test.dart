import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/catalog/models.dart';
import 'package:nirmal_mart/core/catalog/smart_search.dart';
import 'package:nirmal_mart/features/product/product_screen.dart';
import 'package:nirmal_mart/features/search/search_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:nirmal_mart/shared/product_card.dart';

import 'helpers.dart';

Future<void> openSearch(WidgetTester tester, [String path = '/search']) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

Finder get field => find.descendant(of: find.byType(SearchScreen), matching: find.byType(TextField));

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 350)); // suggestions wait for typing to pause
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

List<String> shownNames(WidgetTester tester) =>
    [for (final c in tester.widgetList<ProductCard>(find.byType(ProductCard))) c.product.name];

Product p(Map<String, Object?> j) => Product.fromJson(j);

void main() {
  group('Smart search (on the phone)', () {
    final all = [for (final j in sampleProducts) p(j)];

    test('Marathi letters become a spelling-proof key', () {
      expect(SmartSearch.transliterate('बाटली'), 'batali');
      expect(SmartSearch.key('बाटली'), SmartSearch.key('batli'));
      expect(SmartSearch.key('baatli'), SmartSearch.key('batli'));
      expect(SmartSearch.key('टॉर्च'), SmartSearch.key('torch'));
    });

    test('Marathi typed in English letters finds the Marathi name', () {
      final r = SmartSearch.smartMatch('batli', all);
      expect(r.products.map((x) => x.name), ['Steel Bottle']);
      expect(r.marathiWord, 'बाटली');
    });

    test('other forms of a Marathi word', () {
      final withForms = [...all, p(fakeProduct(20, 'Pill Box Bottle', mr: 'गोळ्यांच्या डब्यासह बाटली', price: 150))];
      final r = SmartSearch.smartMatch('डबा', withForms);
      expect(r.products.map((x) => x.id), [7, 20]); // the lunch box is called डबा too
      expect(r.similar, isTrue);
    });

    test('a spelling slip offers the right word instead of guessing', () {
      expect(SmartSearch.smartMatch('vegtable', all).didYouMean, 'vegetable');
      expect(SmartSearch.smartMatch('botlte', all).didYouMean, 'bottle'); // swapped letters
      expect(SmartSearch.smartMatch('chopper', all).didYouMean, isNull); // exact: just the results
    });

    test('short Marathi words do not match inside unrelated words', () {
      final items = [p(fakeProduct(30, 'Dish Cloth', mr: 'भांडी धुण्याचा कापड', price: 100)), p(fakeProduct(31, 'Foldable Cup', mr: 'फोल्डेबल कप', price: 100))];
      expect(SmartSearch.smartMatch('कप', items).products.map((x) => x.id), [31]);
    });

    test('nothing close → nothing', () {
      final r = SmartSearch.smartMatch('zzzz', all);
      expect(r.products, isEmpty);
      expect(r.didYouMean, isNull);
    });

    test('best match puts name matches ahead of description matches', () {
      final sprayer = p({...fakeProduct(9, 'Garden Sprayer', price: 1800), 'description': 'Fits on any bottle'});
      final bottle = p(fakeProduct(4, 'Steel Bottle', price: 200));
      final brush = p(fakeProduct(5, 'Bottle Brush', price: 100));
      expect(SmartSearch.rank([sprayer, bottle, brush], 'bottle').map((x) => x.id), [5, 4, 9]);
    });
  });

  group('Search screen', () {
    testWidgets('opens from the Home search bar, ready to type, with popular products and categories', (tester) async {
      await startApp(tester, saved: onboarded);
      await tester.tap(find.bySemanticsLabel('Search Nirmal Mart').first);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Search in English or मराठी'), findsOneWidget);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      expect(find.text('Recent searches'), findsNothing); // none yet
      expect(find.text('🔥 Popular right now'), findsOneWidget);
      expect(find.text('Vacuum Cleaner'), findsOneWidget);
      expect(find.text('Browse categories'), findsOneWidget);
      expect(find.text('Tools & Outdoor'), findsOneWidget);
    });

    testWidgets('typing shows suggestions; See all shows results with name matches first', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await type(tester, 'bot');
      expect(find.text('See all results for “bot”'), findsOneWidget);
      expect(find.textContaining('Bottle', findRichText: true), findsWidgets);

      await tester.tap(find.text('See all results for “bot”'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 results', findRichText: true), findsOneWidget);
      expect(shownNames(tester), ['Steel Bottle', 'Garden Sprayer']); // the sprayer only mentions bottle
      expect(app.prefs.getStringList('nm_recent_searches'), ['bot']);
    });

    testWidgets('a suggestion opens the product; the arrow copies its name', (tester) async {
      await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await type(tester, 'lunch');
      await tester.tap(find.byTooltip('Search this name'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'Lunch Box');

      await type(tester, 'lunch');
      await tester.tap(find.textContaining('Lunch', findRichText: true).last);
      await tester.pumpAndSettle();
      expect(find.byType(ProductScreen), findsOneWidget);
    });

    testWidgets('recent searches come back and can be cleared', (tester) async {
      final app = await startApp(tester, saved: {...onboarded, 'nm_recent_searches': ['torch', 'steel bottle']});
      await openSearch(tester);
      expect(find.text('Recent searches'), findsOneWidget);
      await tester.tap(find.text('steel bottle'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 result', findRichText: true), findsOneWidget);
      expect(app.prefs.getStringList('nm_recent_searches'), ['steel bottle', 'torch']);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Recent searches'), findsNothing);
      expect(app.prefs.getStringList('nm_recent_searches'), isNull);
    });

    testWidgets('filters and sort go to the server; empty filters can be cleared', (tester) async {
      final app = await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await search(tester, 'bottle');
      await tester.tap(find.text('Under ₹199'));
      await tester.pumpAndSettle();
      expect(app.api.requests.last.queryParameters['max_price'], 199);
      expect(find.text('Nothing matches these filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), hasLength(2));

      await tester.tap(find.text('Best match'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();
      expect(app.api.requests.last.queryParameters['sort_by'], 'price_high');
      expect(find.text('Price: high to low'), findsOneWidget); // the chip now says it

      await tester.tap(find.text('In stock'));
      await tester.pumpAndSettle();
      expect(app.api.requests.last.queryParameters['in_stock'], true);
    });

    testWidgets('Marathi in English letters: "batli" shows बाटली with a note', (tester) async {
      await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await search(tester, 'batli');
      expect(find.text('Showing results for “batli”: बाटली'), findsOneWidget);
      expect(shownNames(tester), ['Steel Bottle']);
    });

    testWidgets('a spelling slip: no results, then Did you mean …? searches the right word', (tester) async {
      await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await search(tester, 'vegtable');
      expect(find.text('No results for “vegtable”'), findsOneWidget);
      expect(find.text('You might like these'), findsOneWidget);
      await tester.tap(find.textContaining('Did you mean', findRichText: true));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'vegetable');
      expect(shownNames(tester), ['Vegetable Chopper']);

      // sounds the same ("choper" ~ chopper): shown straight away as close matches
      await search(tester, 'choper');
      expect(find.text('Showing close matches'), findsOneWidget);
      expect(shownNames(tester), ['Vegetable Chopper']);
    });

    testWidgets('Marathi app: Marathi labels and a Marathi search', (tester) async {
      await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
      await openSearch(tester);
      expect(find.text('इंग्रजी किंवा मराठीत शोधा'), findsOneWidget);
      expect(find.text('🔥 आता लोकप्रिय'), findsOneWidget);
      await search(tester, 'बाटली');
      expect(find.textContaining('1 निकाल', findRichText: true), findsOneWidget);
      expect(find.text('स्टील बाटली'), findsOneWidget);
      expect(find.text('सर्वोत्तम जुळणारे'), findsOneWidget);
    });

    testWidgets('a link with ?q= opens on the results; offline shows Try again', (tester) async {
      var down = true;
      final routes = catalogueRoutes();
      await startApp(tester, saved: onboarded, api: FakeApi({
        'GET /products': (o) => down && o.queryParameters['search'] != null ? (503, {'detail': 'down'}) : routes['GET /products']!(o),
      }));
      await openSearch(tester, '/search?q=lunch');
      expect(find.text('Couldn’t load the shop'), findsOneWidget);
      down = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Lunch Box']);
    });

    testWidgets('× clears back to the start', (tester) async {
      await startApp(tester, saved: onboarded);
      await openSearch(tester);
      await search(tester, 'bottle');
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.text('🔥 Popular right now'), findsOneWidget);
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
        await startApp(tester, saved: {...onboarded, 'nm_recent_searches': ['a very long search about bottles and boxes', 'torch']});
        await openSearch(tester);
        await type(tester, 'bo');
        await search(tester, 'bottle');
        await search(tester, 'vegtable');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
