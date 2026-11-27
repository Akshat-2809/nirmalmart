import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../prefs.dart';

/// The phone side of push notifications. The real one (Firebase) is plugged in by main();
/// everywhere else (tests, previews) nothing is sent or shown.
abstract class PushPlatform {
  /// Sets up Firebase and the notification channels; [onOpen] gets the page to open when a
  /// notification is tapped (also when the tap started the app).
  Future<void> start({required void Function(String route) onOpen});

  /// This phone's Firebase token (null when unavailable, e.g. offline on first start)
  Future<String?> token();

  Stream<String> get tokenRefresh;

  /// Whether Android lets the app show notifications right now
  Future<bool> allowed();

  /// Android's "Allow Nirmal Mart to send you notifications?" (Android 13+); true if allowed
  Future<bool> ask();
}

class NoPush implements PushPlatform {
  @override
  Future<void> start({required void Function(String route) onOpen}) async {}
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get tokenRefresh => const Stream.empty();
  @override
  Future<bool> allowed() async => false;
  @override
  Future<bool> ask() async => false;
}

final pushPlatformProvider = Provider<PushPlatform>((ref) => NoPush());

/// Settings → Notifications. [orders] / [offers] are the person's choices; [allowed] is whether
/// Android lets us show notifications at all (a switch only shows as on when both are true).
class PushState {
  const PushState({this.allowed = false, this.orders = true, this.offers = true});

  final bool allowed;
  final bool orders;
  final bool offers;

  PushState copyWith({bool? allowed, bool? orders, bool? offers}) =>
      PushState(allowed: allowed ?? this.allowed, orders: orders ?? this.orders, offers: offers ?? this.offers);
}

final pushProvider = NotifierProvider<PushController, PushState>(PushController.new);

class PushController extends Notifier<PushState> {
  static const _ordersKey = 'nm_push_orders';
  static const _offersKey = 'nm_push_offers';
  static const _askedKey = 'nm_push_asked';

  PushPlatform get _platform => ref.read(pushPlatformProvider);

  @override
  PushState build() {
    final prefs = ref.read(sharedPrefsProvider);
    return PushState(orders: prefs.getBool(_ordersKey) ?? true, offers: prefs.getBool(_offersKey) ?? true);
  }

  /// Re-reads Android's permission (it can change in the phone's settings while we're away)
  Future<void> refresh() async {
    final allowed = await _platform.allowed();
    if (allowed != state.allowed) state = state.copyWith(allowed: allowed);
  }

  /// Asked once, after the first order (when updates are clearly useful), never on first launch
  Future<void> askOnce() async {
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(_askedKey) ?? false) return;
    await prefs.setBool(_askedKey, true);
    if (await _platform.allowed()) return refresh();
    state = state.copyWith(allowed: await _platform.ask());
    await sync();
  }

  /// Turns order updates on or off. Returns false when Android blocks notifications for the app
  /// (the person then has to allow them in the phone's settings).
  Future<bool> setOrders(bool on) => _set(_ordersKey, on, (s) => s.copyWith(orders: on));

  Future<bool> setOffers(bool on) => _set(_offersKey, on, (s) => s.copyWith(offers: on));

  Future<bool> _set(String key, bool on, PushState Function(PushState) apply) async {
    if (on && !state.allowed) {
      await ref.read(sharedPrefsProvider).setBool(_askedKey, true);
      final allowed = await _platform.allowed() || await _platform.ask();
      state = state.copyWith(allowed: allowed);
      if (!allowed) return false;
    }
    await ref.read(sharedPrefsProvider).setBool(key, on);
    state = apply(state);
    await sync();
    return true;
  }

  /// Tells the server about this phone: who's signed in (for order updates), the app's language
  /// and the choices above. Signed out = sent without a login, so order updates stop here.
  Future<void> sync() async {
    final token = await _platform.token();
    if (token == null) {
      debugPrint('[push] no Firebase token yet (offline, or no Google Play services on this phone)');
      return;
    }
    final code = ref.read(localeProvider)?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    try {
      await ref.read(apiClientProvider).dio.post('/devices', data: {
        'token': token,
        'platform': 'android',
        'lang': code == 'mr' ? 'mr' : 'en',
        'orders': state.orders,
        'offers': state.offers,
      });
      debugPrint('[push] phone registered (signed in: ${ref.read(authProvider).value != null}, '
          'allowed: ${state.allowed}, orders: ${state.orders}, offers: ${state.offers})');
    } catch (e) {
      debugPrint('[push] registering this phone failed: $e');
      // offline or server asleep: tried again on the next start, sign-in or settings change
    }
  }
}

/// Opens the page a notification points to. Tab pages switch tab; others open on top.
void openNotificationRoute(GoRouter router, String route) {
  if (!route.startsWith('/') || route.startsWith('//')) return;
  final tab = route == '/' || route.startsWith('/shop') || route.startsWith('/wishlist') || route.startsWith('/account');
  tab ? router.go(route) : router.push(route);
}

/// Started once by the app: sets up notifications and keeps the server in step with sign-in,
/// language and token changes.
final pushBootProvider = Provider<void>((ref) {
  final platform = ref.read(pushPlatformProvider);
  final controller = ref.read(pushProvider.notifier);

  // after a frame, so a tap that started the app lands once the first screen is up;
  // scheduleFrame so an idle app (nothing redrawing) still gets that frame
  void open(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) => openNotificationRoute(ref.read(routerProvider), route));
    WidgetsBinding.instance.scheduleFrame();
  }

  StreamSubscription<String>? refreshSub;
  ref.onDispose(() => refreshSub?.cancel());
  unawaited(() async {
    try {
      await platform.start(onOpen: open);
      // only once Firebase is up: Firebase can't be touched before start() finishes
      refreshSub = platform.tokenRefresh.listen((_) => controller.sync());
      await controller.refresh();
      // wait for the saved login, so this phone is registered to the right account first time
      await ref.read(authProvider.future).catchError((_) => null);
      await controller.sync();
    } catch (e) {
      // notifications are a bonus: never stop the app over them
      debugPrint('[push] setup failed: $e');
    }
  }());

  // signed in / out → order updates follow the account
  ref.listen(authProvider.select((a) => a.value?.id), (_, _) => controller.sync());
  ref.listen(localeProvider, (_, _) => controller.sync());
  // back from the phone's settings: notifications may have been allowed or blocked there
  final resume = _OnResume(controller.refresh);
  WidgetsBinding.instance.addObserver(resume);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(resume));
});

class _OnResume with WidgetsBindingObserver {
  _OnResume(this.onResume);

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
