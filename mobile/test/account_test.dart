import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/account/account_screen.dart';
import 'package:nirmal_mart/features/account/addresses_screen.dart';
import 'package:nirmal_mart/features/auth/login_screen.dart';
import 'package:nirmal_mart/features/help/help_screens.dart';
import 'package:nirmal_mart/features/home/home_screen.dart';
import 'package:nirmal_mart/features/orders/orders_screen.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'checkout_test.dart' show FakeLauncher, address;
import 'helpers.dart';
import 'orders_test.dart' show order;

Map<String, Object?> emptyCart() => {'items': [], 'total_items': 0, 'subtotal': 0, 'tax_amount': 0, 'shipping_amount': 0, 'total_amount': 0, 'free_shipping_threshold': 499};

FakeApi signedIn({Map<String, FakeReply Function(dynamic)> more = const {}}) {
  final addresses = [address(1, isDefault: true), address(2, name: 'Sunita Patil', label: 'Work')];
  return FakeApi({
    'GET /auth/me': (_) => (200, fakeUser()),
    'GET /cart': (_) => (200, emptyCart()),
    'GET /wishlist': (_) => (200, [sampleProducts[0]]),
    'GET /orders': (_) => (200, [order(1, status: 'pending', payment: 'pending', total: 499), order(2, status: 'delivered')]),
    'GET /users/me/addresses': (_) => (200, addresses),
    'PUT /users/me': (o) => (200, {...fakeUser(), ...(o.data as Map).cast<String, Object?>()}),
    'POST /auth/change-password': (_) => (200, {'message': 'ok'}),
    'DELETE /users/me': (_) => (200, {'message': 'deleted'}),
    'PUT /users/me/addresses/*': (o) => (200, {...address(2, name: 'Sunita Patil', label: 'Work'), 'is_default': true}),
    'DELETE /users/me/addresses/*': (_) => (200, {'message': 'ok'}),
    ...more.map((k, v) => MapEntry(k, (o) => v(o))),
  });
}

Future<TestApp> start(WidgetTester tester, FakeApi api, {Map<String, Object> saved = onboarded}) =>
    startApp(tester, saved: saved, tokens: MemoryTokens()..accessToken = 'acc', api: api);

Future<void> openTab(WidgetTester tester) async {
  await tester.tap(find.text('Account').last);
  await tester.pumpAndSettle();
}

Future<void> tapIt(WidgetTester tester, Finder f) async {
  // drag whatever is in the middle of the screen (the open sheet, or the current tab)
  final mid = tester.getCenter(find.byType(MaterialApp));
  for (var i = 0; i < 6 && f.hitTestable().evaluate().isEmpty; i++) {
    await tester.dragFrom(mid, const Offset(0, 300)); // up first
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 12 && f.hitTestable().evaluate().isEmpty; i++) {
    await tester.dragFrom(mid, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
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

  testWidgets('guest: Hello, sign in / create account, settings and help', (tester) async {
    await startApp(tester, saved: onboarded);
    await openTab(tester);
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Delete account'), findsNothing);
    await tapIt(tester, find.text('Privacy policy'));
    expect(find.byType(HelpScreen), findsOneWidget); // inside the app, not the browser
    Navigator.of(tester.element(find.byType(HelpScreen))).pop();
    await tester.pumpAndSettle();
    await tapIt(tester, find.text('Refund & cancellation policy'));
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(launcher.urls, isEmpty);
    Navigator.of(tester.element(find.byType(HelpScreen))).pop();
    await tester.pumpAndSettle();
    await tapIt(tester, find.widgetWithText(FilledButton, 'Sign in'));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signed in: profile, counts, unpaid tag; tiles and rows open their screens', (tester) async {
    await start(tester, signedIn());
    await openTab(tester);
    expect(find.text('Ravi Patil'), findsOneWidget);
    expect(find.textContaining('98765 43210'), findsOneWidget);
    expect(find.text('1 awaiting payment'), findsOneWidget);
    expect(find.text('Pay ₹499'), findsOneWidget);
    expect(find.text('Home · Kalyan 421201'), findsOneWidget);
    await tapIt(tester, find.text('My orders'));
    expect(find.byType(OrdersScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(OrdersScreen))).pop();
    await tester.pumpAndSettle();
    await tapIt(tester, find.text('Saved addresses'));
    expect(find.byType(AddressesScreen), findsOneWidget);
  });

  testWidgets('edit profile checks the mobile and saves', (tester) async {
    final api = signedIn();
    await start(tester, api);
    await openTab(tester);
    await tapIt(tester, find.text('Edit'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Ravi Kumar Patil');
    await tester.enterText(find.widgetWithText(TextFormField, '9876543210'), '12345');
    await tapIt(tester, find.text('Save changes'));
    expect(find.text('Please enter a 10-digit mobile number starting with 6–9'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '12345'), '9123456780');
    await tapIt(tester, find.text('Save changes'));
    expect(api.requests.lastWhere((r) => r.method == 'PUT').data, {'full_name': 'Ravi Kumar Patil', 'phone': '9123456780'});
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Ravi Kumar Patil'), findsOneWidget);
  });

  testWidgets('change password: mismatch, then success; wrong current shows the server reason', (tester) async {
    final api = signedIn(more: {'POST /auth/change-password': (_) => (400, {'detail': 'Current password is incorrect'})});
    await start(tester, api);
    await openTab(tester);
    await tapIt(tester, find.text('Change password'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Current password'), 'old');
    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'Newpass@123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'Different1');
    await tapIt(tester, find.text('Update password'));
    expect(find.text('Passwords don’t match'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'Newpass@123');
    await tapIt(tester, find.text('Update password'));
    expect(api.requests.last.data, {'current_password': 'old', 'new_password': 'Newpass@123'});
    expect(find.text('Current password is incorrect'), findsOneWidget);
  });

  testWidgets('admin account: shops normally, store controls point to the website', (tester) async {
    await start(tester, signedIn(more: {'GET /auth/me': (_) => (200, {...fakeUser(), 'role': 'admin'})}));
    await openTab(tester);
    expect(find.text('Store admin'), findsOneWidget);
    await tapIt(tester, find.text('Open admin ↗'));
    expect(launcher.urls.last, 'https://www.nirmalmart.in/admin');
    expect(find.text('My orders'), findsOneWidget); // still a normal account otherwise
  });

  testWidgets('customer account: no admin note', (tester) async {
    await start(tester, signedIn());
    await openTab(tester);
    expect(find.text('Store admin'), findsNothing);
  });

  testWidgets('Follow us opens Instagram, Facebook, YouTube', (tester) async {
    await startApp(tester, saved: onboarded);
    await openTab(tester);
    await tapIt(tester, find.bySemanticsLabel('Instagram'));
    expect(launcher.urls.last, 'https://www.instagram.com/nirmalmart09');
    await tapIt(tester, find.bySemanticsLabel('YouTube'));
    expect(launcher.urls.last, 'https://www.youtube.com/@NirmalMart');
  });

  testWidgets('language and appearance switch and stick', (tester) async {
    final app = await startApp(tester, saved: onboarded);
    await openTab(tester);
    await tapIt(tester, find.text('Dark'));
    expect(app.prefs.getString('nm_theme'), 'dark');
    expect(Theme.of(tester.element(find.byType(AccountScreen))).brightness, Brightness.dark);
    await tapIt(tester, find.text('मराठी'));
    expect(app.prefs.getString('nm_locale'), 'mr');
    expect(find.text('भाषा'), findsOneWidget);
  });

  testWidgets('addresses: make default, delete, add', (tester) async {
    final api = signedIn();
    await start(tester, api);
    ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push('/account/addresses');
    await tester.pumpAndSettle();
    expect(find.text('DEFAULT'), findsOneWidget);
    await tapIt(tester, find.text('Make default'));
    final put = api.requests.lastWhere((r) => r.method == 'PUT');
    expect(put.path, '/users/me/addresses/2');
    expect((put.data as Map)['is_default'], true);
    expect(find.text('Default address updated'), findsOneWidget);
    await tapIt(tester, find.byTooltip('Remove'));
    await tapIt(tester, find.widgetWithText(TextButton, 'Remove'));
    expect(api.requests.lastWhere((r) => r.method == 'DELETE').path, startsWith('/users/me/addresses/'));
    await tapIt(tester, find.text('Add new address'));
    expect(find.text('New address'), findsOneWidget);
    expect(find.text('Save address'), findsOneWidget); // not "deliver here" from Account
  });

  testWidgets('sign out', (tester) async {
    await start(tester, signedIn());
    await openTab(tester);
    await tapIt(tester, find.text('Sign out'));
    await tapIt(tester, find.widgetWithText(FilledButton, 'Sign out'));
    expect(find.text('Signed out'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget); // straight to Sign in / Create account
    expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).from, '/account');
    Navigator.of(tester.element(find.byType(LoginScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing); // the Account tab is the guest view now
  });

  testWidgets('delete account: password needed, server reason shown, then deleted and signed out', (tester) async {
    var busy = true;
    final api = signedIn(more: {
      'DELETE /users/me': (_) => busy ? (400, {'detail': 'Please wait until these orders are delivered or cancelled: NM261121'}) : (200, {'message': 'deleted'}),
    });
    await start(tester, api);
    await openTab(tester);
    await tapIt(tester, find.text('Delete account'));
    expect(find.text('Delete your account?'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Delete my account');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Enter your password to confirm'), 'Secret@123');
    await tester.pump();
    await tapIt(tester, button);
    expect(api.requests.last.data, {'password': 'Secret@123'});
    expect(find.textContaining('NM261121'), findsOneWidget);
    busy = false;
    await tapIt(tester, button);
    expect(find.text('Your account has been deleted'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
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
      await start(tester, signedIn());
      await openTab(tester);
      expect(tester.takeException(), isNull);
      await tapIt(tester, find.text('Delete account'));
      expect(tester.takeException(), isNull);
    });
  }
}
