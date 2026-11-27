import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/prefs.dart';
import 'core/push/firebase_push.dart';
import 'core/push/push.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'shared/update_prompt.dart';

const _showWelcomeEveryTime = kDebugMode && bool.fromEnvironment('SHOW_WELCOME', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // While developing (debug builds) the intro shows on every start and hot restart.
  // Turn off with --dart-define=SHOW_WELCOME=false. Release builds (Play Store) always show it just once.
  if (_showWelcomeEveryTime) await prefs.remove('nm_onboarded');
  runApp(ProviderScope(
    // Failed loads show a Try again button instead of retrying silently in the background
    retry: (_, _) => null,
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      // order updates and offers (Firebase); tests and previews run without it
      pushPlatformProvider.overrideWithValue(FirebasePush()),
    ],
    child: const NirmalMartApp(),
  ));
}

class NirmalMartApp extends ConsumerWidget {
  const NirmalMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushBootProvider); // notifications: set up once, then follows sign-in and language
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider), // null = phone's language (English unless it's Marathi)
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: rootMessengerKey,
      // Google Play update checks (Play Store installs only)
      builder: (context, child) => UpdatePrompt(child: child ?? const SizedBox()),
    );
  }
}
