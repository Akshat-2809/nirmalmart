import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirmal_mart/core/validate.dart';

import 'helpers.dart';

/// Opens the Sign in screen the way the app does (e.g. /login?mode=register)
Future<void> openLogin(WidgetTester tester, [String query = '']) async {
  GoRouter.of(tester.element(find.byType(NavigationBar))).go('/login$query');
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
Finder mainButton(String label) => find.widgetWithText(FilledButton, label);
bool enabled(WidgetTester tester, Finder button) => tester.widget<FilledButton>(button).onPressed != null;

Map<String, dynamic> bodyOf(FakeApi api, String path) =>
    Map<String, dynamic>.from(api.requests.lastWhere((r) => r.path == path).data as Map);

void main() {
  group('Sign in', () {
    testWidgets('signs in, saves the login and returns Home', (tester) async {
      final api = FakeApi({'POST /auth/login': (_) => (200, fakeTokens())});
      final app = await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(enabled(tester, mainButton('Sign in')), isFalse); // nothing typed yet

      await tester.enterText(field('Email or username'), '  ravi@example.com ');
      expect(enabled(tester, mainButton('Sign in')), isFalse);
      await tester.enterText(field('Password'), 'Secret@123');
      await tester.pump();
      expect(enabled(tester, mainButton('Sign in')), isTrue);

      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();

      expect(bodyOf(api, '/auth/login'), {'email': 'ravi@example.com', 'password': 'Secret@123'});
      expect(app.tokens.accessToken, 'acc');
      expect(app.tokens.refreshToken, 'ref');
      expect(find.text('Welcome back, Ravi!'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget); // back on Home
    });

    testWidgets('wrong password shows the server message and stays', (tester) async {
      final api = FakeApi({'POST /auth/login': (_) => (401, {'detail': 'Invalid email or password'})});
      final app = await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester);
      await tester.enterText(field('Email or username'), 'ravi@example.com');
      await tester.enterText(field('Password'), 'nope1234');
      await tester.pump();
      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(app.tokens.accessToken, isNull);
      expect(enabled(tester, mainButton('Sign in')), isTrue); // can try again
    });

    testWidgets('a deleted (inactive) account is told so', (tester) async {
      final api = FakeApi({'POST /auth/login': (_) => (403, {'detail': 'This account has been disabled'})});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester);
      await tester.enterText(field('Email or username'), 'ravi@example.com');
      await tester.enterText(field('Password'), 'Secret@123');
      await tester.pump();
      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('This account has been disabled'), findsOneWidget);
    });

    testWidgets('no internet shows a network message', (tester) async {
      // No route → the fake answers 404; use a throwing route to simulate no connection instead
      final api = FakeApi({'POST /auth/login': (o) => throw Exception('offline')});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester);
      await tester.enterText(field('Email or username'), 'ravi@example.com');
      await tester.enterText(field('Password'), 'Secret@123');
      await tester.pump();
      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Network error — please check your connection'), findsOneWidget);
    });

    testWidgets('returns to the page that asked for sign-in', (tester) async {
      final api = FakeApi({'POST /auth/login': (_) => (200, fakeTokens())});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester, '?from=/bag');
      await tester.enterText(field('Email or username'), 'ravi@example.com');
      await tester.enterText(field('Password'), 'Secret@123');
      await tester.pump();
      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('My bag'), findsOneWidget);
    });

    testWidgets('ignores an outside address in "from"', (tester) async {
      final api = FakeApi({'POST /auth/login': (_) => (200, fakeTokens())});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester, '?from=//evil.example.com');
      await tester.enterText(field('Email or username'), 'ravi@example.com');
      await tester.enterText(field('Password'), 'Secret@123');
      await tester.pump();
      await tester.tap(mainButton('Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('show / hide password', (tester) async {
      await startApp(tester, saved: onboarded);
      await openLogin(tester);
      TextField pw() => tester.widget<TextField>(find.descendant(of: field('Password'), matching: find.byType(TextField)));
      expect(pw().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(pw().obscureText, isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(pw().obscureText, isTrue);
    });

    testWidgets('Forgot password emails a reset link (WhatsApp as a fallback)', (tester) async {
      final api = FakeApi({
        'POST /auth/forgot-password': (_) => (200, {'message': 'If that email has an account, we’ve sent a link.'}),
      });
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email or username'), 'ravi@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Can’t get into your email? WhatsApp us'), findsOneWidget);
      // the email typed on Sign in is filled in
      final box = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      expect(tester.widget<TextField>(box).controller!.text, 'ravi@example.com');
      await tester.enterText(box, 'not-an-email');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(api.requests.where((r) => r.path == '/auth/forgot-password'), isEmpty);

      await tester.enterText(box, ' ravi@example.com ');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(api.requests.last.data, {'email': 'ravi@example.com'});
      expect(find.text('Check your email'), findsOneWidget);
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Check your email'), findsNothing);
    });

    testWidgets('Skip and Back go Home without signing in', (tester) async {
      await startApp(tester, saved: onboarded);
      await openLogin(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);

      await openLogin(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('Create account', () {
    testWidgets('switching tabs shows the extra fields', (tester) async {
      await startApp(tester, saved: onboarded);
      await openLogin(tester);
      expect(field('Full name'), findsNothing);
      expect(field('Mobile number'), findsNothing);

      await tester.tap(find.text('Create account').first); // the tab at the top
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);
      expect(field('Full name'), findsOneWidget);
      expect(field('Email'), findsOneWidget);
      expect(field('Mobile number'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);
      expect(find.textContaining('By creating an account'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign in').last);
      await tester.tap(find.widgetWithText(TextButton, 'Sign in').last); // "Already have an account? Sign in"
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(field('Full name'), findsNothing);
    });

    testWidgets('checks the details before sending anything', (tester) async {
      final api = FakeApi({'POST /auth/register': (_) => (201, fakeTokens())});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester, '?mode=register');

      await tester.enterText(field('Full name'), 'A');
      await tester.enterText(field('Email'), 'not-an-email');
      await tester.enterText(field('Mobile number'), '12345');
      await tester.enterText(field('Password'), 'short');
      await tester.pump();
      await tester.ensureVisible(mainButton('Create account'));
      await tester.tap(mainButton('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name using letters only'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Please enter a 10-digit mobile number starting with 6–9'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(api.requests.where((r) => r.path.startsWith('/auth')), isEmpty); // (Home's catalogue loads behind it)
    });

    testWidgets('mobile keeps digits only and drops a pasted +91', (tester) async {
      await startApp(tester, saved: onboarded);
      await openLogin(tester, '?mode=register');
      await tester.enterText(field('Mobile number'), '+91 98765-43210');
      await tester.pump();
      expect(find.text('9876543210'), findsOneWidget);
      await tester.enterText(field('Full name'), 'Asha 2 Kulkarni');
      await tester.pump();
      expect(find.text('Asha Kulkarni'), findsOneWidget);
    });

    testWidgets('creates the account and signs in', (tester) async {
      final api = FakeApi({'POST /auth/register': (_) => (201, fakeTokens(name: 'Asha Kulkarni'))});
      final app = await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester, '?mode=register');

      await tester.enterText(field('Full name'), 'Asha Kulkarni ');
      await tester.enterText(field('Email'), ' asha@example.com');
      await tester.enterText(field('Mobile number'), '9876543210');
      await tester.enterText(field('Password'), 'Strong@123');
      await tester.pump();
      expect(find.textContaining('Strong ·'), findsOneWidget); // strength meter
      await tester.ensureVisible(mainButton('Create account'));
      await tester.tap(mainButton('Create account'));
      await tester.pumpAndSettle();

      expect(bodyOf(api, '/auth/register'), {
        'full_name': 'Asha Kulkarni',
        'email': 'asha@example.com',
        'phone': '9876543210',
        'password': 'Strong@123',
      });
      expect(app.tokens.accessToken, 'acc');
      expect(find.text('Welcome to Nirmal Mart, Asha! 🎉'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('email already registered shows the server message', (tester) async {
      final api = FakeApi({'POST /auth/register': (_) => (400, {'detail': 'Email already registered'})});
      await startApp(tester, saved: onboarded, api: api);
      await openLogin(tester, '?mode=register');
      await tester.enterText(field('Full name'), 'Asha Kulkarni');
      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.enterText(field('Mobile number'), '9876543210');
      await tester.enterText(field('Password'), 'Strong@123');
      await tester.pump();
      await tester.ensureVisible(mainButton('Create account'));
      await tester.tap(mainButton('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Email already registered'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
    });
  });

  group('Saved login', () {
    testWidgets('already signed in: Sign in screen is skipped', (tester) async {
      final api = FakeApi({'GET /auth/me': (_) => (200, fakeUser())});
      await startApp(tester, saved: onboarded, api: api, tokens: MemoryTokens()..accessToken = 'acc');
      await openLogin(tester);
      expect(find.text('Welcome back'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a login the server no longer accepts is cleared', (tester) async {
      final api = FakeApi({
        'GET /auth/me': (_) => (401, {'detail': 'Not authenticated'}),
        'POST /auth/refresh': (_) => (401, {'detail': 'Invalid refresh token'}),
      });
      final tokens = MemoryTokens()..accessToken = 'old';
      await startApp(tester, saved: onboarded, api: api, tokens: tokens);
      await openLogin(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(tokens.accessToken, isNull);
    });
  });

  testWidgets('Marathi', (tester) async {
    await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
    await openLogin(tester);
    expect(find.text('पुन्हा स्वागत आहे'), findsOneWidget);
    expect(field('ईमेल किंवा युजरनेम'), findsOneWidget);
    expect(find.text('पासवर्ड विसरलात?'), findsOneWidget);
    await tester.tap(find.text('खाते तयार करा').first);
    await tester.pumpAndSettle();
    expect(field('मोबाईल नंबर'), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, saved: onboarded);
    await openLogin(tester, '?mode=register');
    expect(tester.takeException(), isNull);
  });

  group('Validate (same rules as the website)', () {
    test('mobile', () {
      expect(Validate.cleanMobile('+91 98765 43210'), '9876543210');
      expect(Validate.cleanMobile('09876543210'), '9876543210');
      expect(Validate.isMobile('9876543210'), isTrue);
      expect(Validate.isMobile('5876543210'), isFalse);
      expect(Validate.isMobile('987654321'), isFalse);
    });
    test('name', () {
      expect(Validate.cleanName(' Ravi123 Patil'), 'Ravi Patil');
      expect(Validate.isName('रवी पाटील'), isTrue);
      expect(Validate.isName("D'Souza"), isTrue);
      expect(Validate.isName('R'), isFalse);
    });
    test('password strength', () {
      expect(Validate.passwordStrength('abc'), 0);
      expect(Validate.passwordStrength('abcdefgh'), 1);
      expect(Validate.passwordStrength('Strong@123'), 4);
    });
    test('fake API answers JSON', () => expect(jsonEncode(fakeTokens()), contains('acc')));
  });
}
