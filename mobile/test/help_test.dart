import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/features/help/help_content.dart';
import 'package:nirmal_mart/features/help/help_screens.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/router.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'checkout_test.dart' show FakeLauncher;
import 'helpers.dart';

Future<void> open(WidgetTester tester, String path) async {
  ProviderScope.containerOf(tester.element(find.byType(NirmalMartApp))).read(routerProvider).push(path);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 40 && f.hitTestable().evaluate().isEmpty; i++) {
    await tester.dragFrom(tester.getCenter(find.byType(MaterialApp)), const Offset(0, -250));
    await tester.pumpAndSettle();
  }
}

void main() {
  test('help text has no leftover placeholders', () {
    for (final c in helpContent.values) {
      final all = [
        c.faqIntro, for (final f in c.faqs) ...[f.q, f.a],
        c.shippingIntro, for (final f in c.facts) ...[f.title, f.value, f.body],
        c.privacyIntro, for (final s in c.privacy) ...[s.title, ...s.points],
        c.termsIntro, for (final s in c.terms) ...[s.title, ...s.points],
        c.refundsIntro, for (final s in c.refunds) ...[s.title, ...s.points],
      ];
      for (final t in all) {
        expect(t, isNot(matches(RegExp(r'undefined|null|PRIVACY_UPDATED|PHONE|PAYMENT|\$\{'))), reason: t);
      }
    }
  });

  late FakeLauncher launcher;
  setUp(() {
    launcher = FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  testWidgets('FAQs: first answer open, others fold out; app-correct answers', (tester) async {
    await startApp(tester, saved: onboarded);
    await open(tester, '/help/faq');
    expect(find.text('How long does delivery take?'), findsOneWidget);
    expect(find.textContaining('2–7 days'), findsOneWidget);
    await reveal(tester, find.text('How can I pay?'));
    await tester.tap(find.text('How can I pay?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pay by UPI'), findsOneWidget);
    expect(find.textContaining('net banking'), findsNothing);
  });

  testWidgets('a link can open a particular answer', (tester) async {
    await startApp(tester, saved: onboarded);
    await open(tester, '/help/faq?open=returns');
    await reveal(tester, find.textContaining('within 5 days of delivery'));
    expect(find.textContaining('within 5 days of delivery'), findsOneWidget);
  });

  testWidgets('shipping, privacy and terms', (tester) async {
    await startApp(tester, saved: onboarded);
    await open(tester, '/help/shipping');
    expect(find.text('On orders of ₹499+'), findsOneWidget);
    await open(tester, '/help/privacy');
    expect(find.textContaining('What we collect', findRichText: true), findsOneWidget);
    await open(tester, '/help/terms');
    expect(find.textContaining('Your account', findRichText: true), findsOneWidget);
    await open(tester, '/help/refunds');
    expect(find.text('Refund & cancellation policy'), findsOneWidget);
    expect(find.textContaining('Cancelling an order', findRichText: true), findsOneWidget);
    expect(find.textContaining('Account → My orders'), findsWidgets); // the app's menu names, not the website's
    expect(launcher.urls, isEmpty);
  });

  testWidgets('Marathi', (tester) async {
    await startApp(tester, saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
    await open(tester, '/help/faq');
    expect(find.text('डिलिव्हरीला किती वेळ लागतो?'), findsOneWidget);
    await open(tester, '/help/privacy');
    expect(find.textContaining('आम्ही काय गोळा करतो', findRichText: true), findsOneWidget);
  });

  testWidgets('Contact us: WhatsApp, Email or Call, each opens its app', (tester) async {
    await startApp(tester, saved: onboarded);
    await open(tester, '/help/faq');
    await reveal(tester, find.widgetWithText(TextButton, 'Contact us'));
    await tester.tap(find.widgetWithText(TextButton, 'Contact us'));
    await tester.pumpAndSettle();
    expect(find.text('Chat on WhatsApp'), findsOneWidget);
    await tester.tap(find.text('Call us'));
    await tester.pumpAndSettle();
    expect(launcher.urls.last, 'tel:+917498299375');

    await tester.tap(find.widgetWithText(TextButton, 'Contact us'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat on WhatsApp'));
    await tester.pumpAndSettle();
    expect(Uri.parse(launcher.urls.last).host, 'wa.me');

    await tester.tap(find.widgetWithText(TextButton, 'Contact us'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Email us'));
    await tester.pumpAndSettle();
    expect(launcher.urls.last, 'mailto:support@nirmalmart.in');
  });

  testWidgets('no dialer: says which number to call', (tester) async {
    launcher.canOpen = false;
    await startApp(tester, saved: onboarded);
    await open(tester, '/help/terms');
    await reveal(tester, find.widgetWithText(TextButton, 'Contact us'));
    await tester.tap(find.widgetWithText(TextButton, 'Contact us'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call us'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t open the dialer — call +91 74982 99375'), findsOneWidget);
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
      await startApp(tester, saved: onboarded);
      for (final p in HelpPage.values) {
        await open(tester, '/help/${p.name}');
        await reveal(tester, find.widgetWithText(TextButton, 'Contact us'));
        expect(tester.takeException(), isNull, reason: p.name);
      }
      await tester.tap(find.widgetWithText(TextButton, 'Contact us').hitTestable());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
