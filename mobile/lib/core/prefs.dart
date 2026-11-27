import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in main() before the app starts, so the first frame already knows the saved choices.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider in main()'),
);

/// App language picked on the welcome screen or in Account. null = follow the phone's language.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'nm_locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPrefsProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(sharedPrefsProvider).setString(_key, locale.languageCode);
  }
}

/// Light / dark / follow the phone (Account → Appearance)
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'nm_theme';

  @override
  ThemeMode build() => switch (ref.watch(sharedPrefsProvider).getString(_key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

/// Whether the welcome screen has been completed (it only shows on first launch)
final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(OnboardedNotifier.new);

class OnboardedNotifier extends Notifier<bool> {
  static const _key = 'nm_onboarded';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}
