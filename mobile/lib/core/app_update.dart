import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

/// What Google Play says about updates for this app
class UpdateCheck {
  const UpdateCheck({
    required this.available,
    this.downloaded = false,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.priority = 0,
    this.staleDays,
  });

  final bool available;

  /// A background download already finished (just needs a restart)
  final bool downloaded;
  final bool immediateAllowed;
  final bool flexibleAllowed;

  /// 0–5, set per release through the Play Developer API (4+ = must update now)
  final int priority;

  /// Days since Play first offered this update to this phone
  final int? staleDays;

  /// Full-screen "Update now": urgent releases, or after ignoring an update for 3 weeks
  bool get mustUpdate => immediateAllowed && (priority >= 4 || (staleDays ?? 0) >= 21);
}

enum UpdateOutcome { accepted, declined, failed }

/// Google Play in-app updates. Only works for installs from the Play Store; elsewhere checks
/// simply fail and nothing is shown.
abstract class Updater {
  bool get supported;
  Future<UpdateCheck> check();

  /// Play's own full-screen update
  Future<UpdateOutcome> immediate();

  /// Play's small prompt, then a background download; completes when the download is done
  Future<UpdateOutcome> flexible();

  /// Installs a finished background download (restarts the app)
  Future<void> install();
}

class PlayUpdater implements Updater {
  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<UpdateCheck> check() async {
    final i = await InAppUpdate.checkForUpdate();
    return UpdateCheck(
      available: i.updateAvailability == UpdateAvailability.updateAvailable,
      downloaded: i.installStatus == InstallStatus.downloaded,
      immediateAllowed: i.immediateUpdateAllowed,
      flexibleAllowed: i.flexibleUpdateAllowed,
      priority: i.updatePriority,
      staleDays: i.clientVersionStalenessDays,
    );
  }

  static UpdateOutcome _map(AppUpdateResult r) => switch (r) {
        AppUpdateResult.success => UpdateOutcome.accepted,
        AppUpdateResult.userDeniedUpdate => UpdateOutcome.declined,
        AppUpdateResult.inAppUpdateFailed => UpdateOutcome.failed,
      };

  @override
  Future<UpdateOutcome> immediate() async => _map(await InAppUpdate.performImmediateUpdate());

  @override
  Future<UpdateOutcome> flexible() async => _map(await InAppUpdate.startFlexibleUpdate());

  @override
  Future<void> install() => InAppUpdate.completeFlexibleUpdate();
}

final updaterProvider = Provider<Updater>((ref) => PlayUpdater());
