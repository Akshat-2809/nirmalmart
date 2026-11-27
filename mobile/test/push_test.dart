import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirmal_mart/core/push/push.dart';
import 'package:nirmal_mart/features/orders/order_detail_screen.dart';
import 'package:nirmal_mart/features/product/product_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';

import 'account_test.dart' show openTab, signedIn, tapIt;
import 'checkout_test.dart' as checkout;
import 'helpers.dart';

/// Stands in for Firebase: a fixed token, a switchable Android permission, and taps on demand
class FakePush implements PushPlatform {
  FakePush({this.allowedNow = false, this.grant = true});

  bool allowedNow;
  bool grant;
  int asked = 0;
  void Function(String)? open;
  final refresh = StreamController<String>.broadcast();

  @override
  Future<void> start({required void Function(String route) onOpen}) async => open = onOpen;
  @override
  Future<String?> token() async => 'fcm-token-for-this-phone-0123456789';
  @override
  Stream<String> get tokenRefresh {
    // like Firebase: unusable until start() has run
    if (open == null) throw StateError('[core/no-app] No Firebase App has been created');
    return refresh.stream;
  }
  @override
  Future<bool> allowed() async => allowedNow;
  @override
  Future<bool> ask() async {
    asked++;
    return allowedNow = grant;
  }
}

List<Map<String, Object?>> registrations(FakeApi api) => [
      for (final r in api.requests)
        if (r.method == 'POST' && r.path == '/devices') {...(r.data as Map).cast<String, Object?>(), 'auth': r.headers['Authorization']},
    ];

Finder switchFor(String title) =>
    find.descendant(of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first, matching: find.byType(Switch));

void main() {
  testWidgets('registers this phone with the signed-in account and the app language', (tester) async {
    final push = FakePush(allowedNow: true);
    final api = signedIn();
    await startApp(tester, saved: {...onboarded, 'nm_locale': 'mr'}, tokens: MemoryTokens()..accessToken = 'acc', api: api,
        extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    final r = registrations(api).last;
    expect(r['token'], 'fcm-token-for-this-phone-0123456789');
    expect(r['lang'], 'mr');
    expect(r['orders'], true);
    expect(r['offers'], true);
    expect(r['auth'], 'Bearer acc');
    expect(push.asked, 0, reason: 'never asks on first launch');
  });

  testWidgets('Settings: guests only see offers; switching on asks Android; blocked shows how to fix it', (tester) async {
    final push = FakePush(grant: false);
    final api = FakeApi();
    await startApp(tester, saved: onboarded, api: api, extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    await openTab(tester);
    await tapIt(tester, find.text('Offers & deals'));
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('Order updates'), findsNothing);
    expect(tester.widget<Switch>(switchFor('Offers & deals')).value, false);

    await tester.tap(switchFor('Offers & deals'));
    await tester.pumpAndSettle();
    expect(push.asked, 1);
    expect(find.textContaining('Notifications are off for Nirmal Mart'), findsOneWidget);
    expect(tester.widget<Switch>(switchFor('Offers & deals')).value, false);

    push.grant = true;
    await tester.tap(switchFor('Offers & deals'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFor('Offers & deals')).value, true);
    expect(registrations(api).last['auth'], isNull, reason: 'a guest is registered without a login');
  });

  testWidgets('signed in: order updates can be turned off, and sign out stops them on this phone', (tester) async {
    final push = FakePush(allowedNow: true);
    final api = signedIn();
    final app = await startApp(tester, saved: onboarded, tokens: MemoryTokens()..accessToken = 'acc', api: api,
        extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    await openTab(tester);
    await tapIt(tester, find.text('Order updates'));
    expect(tester.widget<Switch>(switchFor('Order updates')).value, true);
    await tester.tap(switchFor('Order updates'));
    await tester.pumpAndSettle();
    expect(registrations(api).last['orders'], false);
    expect(registrations(api).last['offers'], true);
    expect(app.prefs.getBool('nm_push_orders'), false);

    await tapIt(tester, find.text('Sign out'));
    if (find.widgetWithText(FilledButton, 'Sign out').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
    }
    expect(registrations(api).last['auth'], isNull);
  });

  testWidgets('asked once, after the first order is placed', (tester) async {
    final push = FakePush();
    final app = await startApp(tester, saved: onboarded, tokens: MemoryTokens()..accessToken = 'acc', api: checkout.signedInApi(),
        extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    await checkout.go(tester, '/order/77/placed');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(push.asked, 1);
    expect(app.prefs.getBool('nm_push_asked'), true);

    final router = ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider);
    router.go('/');
    await tester.pumpAndSettle();
    await checkout.go(tester, '/order/77/placed');
    await tester.pump(const Duration(seconds: 2));
    expect(push.asked, 1, reason: 'not asked again');
  });

  testWidgets('tapping a notification opens its page', (tester) async {
    final push = FakePush(allowedNow: true);
    await startApp(tester, saved: onboarded, tokens: MemoryTokens()..accessToken = 'acc',
        api: checkout.signedInApi(more: {'GET /orders/77': (_) => (200, checkout.order(status: 'shipped', payment: 'paid'))}),
        extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    push.open!('/account/orders/77');
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);

    push.open!('/product/steel-bottle');
    await tester.pumpAndSettle();
    expect(find.byType(ProductScreen), findsOneWidget);

    push.open!('//evil.example/x'); // ignored
    await tester.pumpAndSettle();
    expect(find.byType(ProductScreen), findsOneWidget);
  });

  testWidgets('a new Firebase token is sent to the server', (tester) async {
    final push = FakePush(allowedNow: true);
    final api = FakeApi();
    await startApp(tester, saved: onboarded, api: api, extraOverrides: [pushPlatformProvider.overrideWithValue(push)]);
    final before = registrations(api).length;
    push.refresh.add('new');
    await tester.pumpAndSettle();
    expect(registrations(api).length, before + 1);
  });

  test('openNotificationRoute: tab pages switch tab, others open on top', () {
    final calls = <String>[];
    final router = _RecordingRouter(calls);
    openNotificationRoute(router, '/shop?category=kitchen');
    openNotificationRoute(router, '/product/x');
    openNotificationRoute(router, 'https://evil.example');
    expect(calls, ['go /shop?category=kitchen', 'push /product/x']);
  });
}

class _RecordingRouter extends Fake implements GoRouter {
  _RecordingRouter(this.calls);

  final List<String> calls;

  @override
  void go(String location, {Object? extra}) => calls.add('go $location');

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    calls.add('push $location');
    return null;
  }
}
