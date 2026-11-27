import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/prefs.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/entrance.dart';
import '../../shared/press_scale.dart';

/// First-launch intro: brand, tagline, language choice (English / मराठी), then sign in or browse as a guest.
/// Design: nirmal-mart-app-design/screens/android/Welcome.dc.html
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with SingleTickerProviderStateMixin {
  // Entrance: the logo grows in, then each line fades and slides up on its own delay. Plays once.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1350));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1; // phone's "remove animations" setting: show everything at once
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  String get _lang => ref.watch(localeProvider)?.languageCode ?? Localizations.localeOf(context).languageCode;

  Future<void> _finish(String route) async {
    // Save the shown language even if the user never tapped one, so it doesn't change later with the phone's
    final notifier = ref.read(localeProvider.notifier);
    if (ref.read(localeProvider) == null) await notifier.set(Locale(_lang == 'mr' ? 'mr' : 'en'));
    await ref.read(onboardedProvider.notifier).complete();
    if (mounted) context.go(route);
  }

  /// Fade + slide up 16 px, starting [delayMs] after the screen opens
  Widget _up(int delayMs, Widget child) => Entrance(controller: _intro, delayMs: delayMs, child: child);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme; // button styles must start from these to keep Inter
    final lang = _lang;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: NmColors.brand,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NmColors.brand,
        body: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Fills the screen; scrolls only on very short phones or with large system text
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The logo takes whatever height the text and buttons leave (at least 120 px)
                    Expanded(child: _ClaimsHeight(height: 120, child: _LogoHero(controller: _intro))),
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ScaleIn(controller: _intro, child: const _Brand()),
                          const SizedBox(height: 14),
                          _up(
                            250,
                            const Text(
                              'Trending gadgets & everyday essentials',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.1, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _up(
                            350,
                            Text(
                              'ट्रेंडिंग गॅझेट्स आणि रोजच्या गरजेच्या वस्तू',
                              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _up(
                            550,
                            Text(
                              'Choose your language · भाषा निवडा',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _up(
                            600,
                            Row(
                              children: [
                                for (final (i, opt) in _languages.indexed) ...[
                                  if (i > 0) const SizedBox(width: 10),
                                  Expanded(
                                    child: _LanguageOption(
                                      option: opt,
                                      selected: lang == opt.code,
                                      onTap: () => ref.read(localeProvider.notifier).set(Locale(opt.code)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _up(
                            700,
                            PressScale(
                              child: FilledButton(
                                onPressed: () => _finish('/login'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: NmColors.ink,
                                  textStyle: text.labelLarge!.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(child: Text(l.welcomeGetStarted, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _up(
                            800,
                            TextButton(
                              onPressed: () => _finish('/'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(NmSizes.minTouch),
                                textStyle: text.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              child: Text(l.welcomeBrowseGuest),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Lang = ({String code, String name, String sub});

const List<_Lang> _languages = [
  (code: 'en', name: 'English', sub: 'Continue in English'),
  (code: 'mr', name: 'मराठी', sub: 'मराठीत सुरू ठेवा'),
];

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'NIRMAL ',
        children: [TextSpan(text: 'MART', style: TextStyle(color: NmColors.gold))],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: Colors.white),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.option, required this.selected, required this.onTap});

  final _Lang option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(NmRadius.card);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: PressScale(
        child: Material(
          color: selected ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.35), width: 2),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                          // Shrinks a little rather than cut off on narrow phones
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(option.sub, maxLines: 1, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _Radio(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      // Dot pops in when chosen (design: scale 0.6 → 1.3 → 1)
      child: selected
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 450),
              builder: (context, t, child) => Transform.scale(scale: _pop(t), child: child),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: SizedBox(width: 10, height: 10),
              ),
            )
          : null,
    );
  }

  static double _pop(double t) => t < 0.5 ? 0.6 + (1.3 - 0.6) * (t / 0.5) : 1.3 - 0.3 * ((t - 0.5) / 0.5);
}

/// The Nirmal Mart logo, large, in a white circle with a soft glow. Grows in once when the screen opens.
class _LogoHero extends StatelessWidget {
  const _LogoHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width * 0.58, 240.0);
    final total = controller.duration!.inMilliseconds;
    final anim = CurvedAnimation(parent: controller, curve: Interval(0, 700 / total, curve: NmMotion.entranceCurve));
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        // Shrinks on short screens instead of pushing the buttons off
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(anim),
              child: Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(size * 0.12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // soft light halo around the circle, plus a gentle drop shadow
                    BoxShadow(color: Colors.white.withValues(alpha: 0.22), blurRadius: 60, spreadRadius: 18),
                    const BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, 14)),
                  ],
                ),
                child: SvgPicture.asset('assets/images/logo-mark.svg', semanticsLabel: 'Nirmal Mart'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleIn extends StatelessWidget {
  const _ScaleIn({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Design: from scale 0.4, -12°, transparent → normal over 700 ms with a slight overshoot, after 100 ms
    final total = controller.duration!.inMilliseconds;
    final anim = CurvedAnimation(parent: controller, curve: Interval(100 / total, 800 / total, curve: const Cubic(0.2, 1.4, 0.4, 1)));
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.rotate(
            angle: (1 - t) * -12 * math.pi / 180,
            alignment: Alignment.centerLeft,
            child: Transform.scale(scale: 0.4 + 0.6 * t, alignment: Alignment.centerLeft, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// Tells the scroll layout this child only needs [height], so on short screens the logo shrinks to fit
/// (via its FittedBox) instead of pushing the buttons below the fold.
class _ClaimsHeight extends SingleChildRenderObjectWidget {
  const _ClaimsHeight({required this.height, super.child});

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderClaimsHeight(height);

  @override
  void updateRenderObject(BuildContext context, _RenderClaimsHeight renderObject) => renderObject.height = height;
}

class _RenderClaimsHeight extends RenderProxyBox {
  _RenderClaimsHeight(this._height);

  double _height;
  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;
}
