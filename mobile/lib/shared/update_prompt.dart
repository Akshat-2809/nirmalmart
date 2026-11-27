import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_update.dart';
import '../core/prefs.dart';
import '../l10n/app_localizations.dart';

/// The app's top-level messenger, so app-wide notices (like "Update ready") can show on any screen
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Checks Google Play for a newer version a few seconds after the app opens and whenever it comes
/// back to the foreground:
/// - usually Play's small prompt; the update downloads while people keep shopping, then a
///   "Restart to update" banner appears
/// - for urgent releases, or after ignoring an update for 3 weeks, Play's full-screen update
/// "Not now" isn't asked again for a day.
class UpdatePrompt extends ConsumerStatefulWidget {
  const UpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> with WidgetsBindingObserver {
  static const _declinedKey = 'nm_update_declined_at';
  static const firstCheckDelay = Duration(seconds: 3);

  late final Updater _updater = ref.read(updaterProvider);
  Timer? _first;
  bool _busy = false;
  bool _bannerShown = false;

  @override
  void initState() {
    super.initState();
    if (!_updater.supported) return;
    WidgetsBinding.instance.addObserver(this);
    _first = Timer(firstCheckDelay, _check); // not during the first moments of opening the app
  }

  @override
  void dispose() {
    _first?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  bool get _declinedRecently {
    final at = ref.read(sharedPrefsProvider).getInt(_declinedKey);
    return at != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) < const Duration(hours: 24);
  }

  void _noteDeclined() => ref.read(sharedPrefsProvider).setInt(_declinedKey, DateTime.now().millisecondsSinceEpoch);

  Future<void> _check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final info = await _updater.check();
      if (info.downloaded) return _showReady();
      if (!info.available) return;
      if (info.mustUpdate) {
        if (await _updater.immediate() == UpdateOutcome.declined) _noteDeclined();
        return;
      }
      if (!info.flexibleAllowed || _declinedRecently) return;
      final r = await _updater.flexible();
      if (r == UpdateOutcome.accepted) {
        _showReady();
      } else if (r == UpdateOutcome.declined) {
        _noteDeclined();
      }
    } catch (_) {
      // not installed from Play, offline, Play busy… try again next time
    } finally {
      _busy = false;
    }
  }

  void _showReady() {
    final messenger = rootMessengerKey.currentState;
    if (_bannerShown || messenger == null || !mounted) return;
    _bannerShown = true;
    final l = AppLocalizations.of(messenger.context);
    messenger.showMaterialBanner(MaterialBanner(
      leading: const Icon(Icons.system_update_rounded),
      content: Text(l.updateReady),
      actions: [
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            _bannerShown = false;
          },
          child: Text(l.later),
        ),
        FilledButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            _updater.install();
          },
          child: Text(l.restart),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
