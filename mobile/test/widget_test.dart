import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/api/api_client.dart';

import 'helpers.dart';

void main() {
  group('Welcome screen', () {
    testWidgets('shows on first launch with English chosen', (tester) async {
      await startApp(tester);
      expect(find.text('Trending gadgets & everyday essentials'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Browse as guest'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);
      expect(find.text('Home'), findsNothing); // no tab bar yet
    });

    testWidgets('picking मराठी switches the buttons to Marathi and is remembered', (tester) async {
      final prefs = (await startApp(tester)).prefs;
      await tester.tap(find.text('मराठी'));
      await tester.pumpAndSettle();
      expect(find.text('पुढे चला'), findsOneWidget);
      expect(find.text('लॉगिन न करता ब्राउझ करा'), findsOneWidget);
      expect(prefs.getString('nm_locale'), 'mr');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(prefs.getString('nm_locale'), 'en');
    });

    testWidgets('Browse as guest opens Home and is not shown again', (tester) async {
      final prefs = (await startApp(tester)).prefs;
      await tester.tap(find.text('Browse as guest'));
      await tester.pumpAndSettle();
      expect(find.text('Search Nirmal Mart'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(prefs.getBool('nm_onboarded'), isTrue);
      expect(prefs.getString('nm_locale'), 'en'); // the shown language is saved
    });

    testWidgets('Get started opens Sign in', (tester) async {
      await startApp(tester);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('Marathi guest lands on a Marathi Home', (tester) async {
      await startApp(tester);
      await tester.tap(find.text('मराठी'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('लॉगिन न करता ब्राउझ करा'));
      await tester.pumpAndSettle();
      expect(find.text('होम'), findsWidgets);
      expect(find.text('खरेदी'), findsOneWidget);
    });

    testWidgets('skipped once completed', (tester) async {
      await startApp(tester, saved: onboarded);
      expect(find.text('Get started'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('fits a small phone with large text, without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await startApp(tester);
      expect(tester.takeException(), isNull);
      // Doesn't fit at this size, so the screen scrolls to reach the button
      await tester.ensureVisible(find.text('Browse as guest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Browse as guest'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('runs its animations without errors', (tester) async {
      await startApp(tester, animate: true);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500)); // entrance finishes, tiles keep floating
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('मराठी'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('पुढे चला'), findsOneWidget);
      await tester.tap(find.text('लॉगिन न करता ब्राउझ करा'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NavigationBar), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      debugPrint('PENDING after 40s check');
    });
  });

  testWidgets('tabs switch screens', (tester) async {
    await startApp(tester, saved: onboarded);
    for (final tab in ['Home', 'Shop', 'Wishlist', 'Account']) {
      expect(find.text(tab), findsWidgets);
    }
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('9 products'), findsWidgets); // the Shop tab, everything
    await tester.tap(find.text('Wishlist').last);
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);
    await tester.tap(find.text('Account').last);
    await tester.pumpAndSettle();
    expect(find.text('Hello!'), findsOneWidget);
  });

  test('errorMessage reads FastAPI errors like the website does', () {
    DioException err(Object detail) => DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 422, data: {'detail': detail}),
        );
    expect(errorMessage(err('Out of stock')), 'Out of stock');
    expect(
      errorMessage(err([
        {'loc': ['body', 'phone'], 'msg': "String should match pattern '^[6-9]\\d{9}\$'"}
      ])),
      'Please enter a valid 10-digit mobile number',
    );
    expect(errorMessage(DioException(requestOptions: RequestOptions())), 'Network error — please check your connection');
  });
}
