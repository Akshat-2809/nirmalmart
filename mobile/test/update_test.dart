import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/app_update.dart';

import 'helpers.dart';

/// Google Play stand-in
class FakePlay implements Updater {
  FakePlay(this.info, {this.answer = UpdateOutcome.accepted});

  UpdateCheck info;
  UpdateOutcome answer;
  final calls = <String>[];

  @override
  bool get supported => true;

  @override
  Future<UpdateCheck> check() async {
    calls.add('check');
    return info;
  }

  @override
  Future<UpdateOutcome> immediate() async {
    calls.add('immediate');
    return answer;
  }

  @override
  Future<UpdateOutcome> flexible() async {
    calls.add('flexible');
    return answer;
  }

  @override
  Future<void> install() async => calls.add('install');
}

Future<TestApp> start(WidgetTester tester, FakePlay play, {Map<String, Object> saved = onboarded}) async {
  final app = await startApp(tester, saved: saved, extraOverrides: [updaterProvider.overrideWithValue(play)]);
  await tester.pump(const Duration(seconds: 4)); // the first check waits a few seconds after opening
  await tester.pumpAndSettle();
  return app;
}

const normal = UpdateCheck(available: true, flexibleAllowed: true, immediateAllowed: true, staleDays: 2);

void main() {
  testWidgets('no update: nothing shown', (tester) async {
    final play = FakePlay(const UpdateCheck(available: false));
    await start(tester, play);
    expect(play.calls, ['check']);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('normal update: background download, then Restart installs it', (tester) async {
    final play = FakePlay(normal);
    await start(tester, play);
    expect(play.calls, ['check', 'flexible']);
    expect(find.text('A new version of Nirmal Mart is ready. Restart to use it.'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(play.calls.last, 'install');
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('Later hides the banner', (tester) async {
    await start(tester, FakePlay(normal));
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('ignored for 3 weeks: Play’s full-screen update', (tester) async {
    final play = FakePlay(const UpdateCheck(available: true, flexibleAllowed: true, immediateAllowed: true, staleDays: 22));
    await start(tester, play);
    expect(play.calls, ['check', 'immediate']);
  });

  testWidgets('urgent release (priority 4+): full-screen update', (tester) async {
    final play = FakePlay(const UpdateCheck(available: true, immediateAllowed: true, priority: 5));
    await start(tester, play);
    expect(play.calls, ['check', 'immediate']);
  });

  testWidgets('"Not now" is remembered for a day', (tester) async {
    final play = FakePlay(normal, answer: UpdateOutcome.declined);
    final app = await start(tester, play);
    expect(play.calls, ['check', 'flexible']);
    expect(app.prefs.getInt('nm_update_declined_at'), isNotNull);
    // back to the app: checked again, but not asked again today
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(play.calls, ['check', 'flexible', 'check']);
  });

  testWidgets('download finished earlier: banner straight away', (tester) async {
    final play = FakePlay(const UpdateCheck(available: false, downloaded: true));
    await start(tester, play);
    expect(find.byType(MaterialBanner), findsOneWidget);
  });

  testWidgets('Play not reachable: silent', (tester) async {
    final play = _Broken();
    await startApp(tester, saved: onboarded, extraOverrides: [updaterProvider.overrideWithValue(play)]);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Marathi banner', (tester) async {
    await start(tester, FakePlay(normal), saved: {'nm_onboarded': true, 'nm_locale': 'mr'});
    expect(find.text('रीस्टार्ट'), findsOneWidget);
  });
}

class _Broken extends FakePlay {
  _Broken() : super(normal);

  @override
  Future<UpdateCheck> check() => Future.error(Exception('not installed from Play'));
}
