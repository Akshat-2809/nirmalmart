import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'forgot_password_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/validate.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/entrance.dart';
import '../../shared/press_scale.dart';

/// Sign in / Create account, on one screen with a switch at the top.
/// Design: nirmal-mart-app-design/screens/android/Login.dc.html. Rules match the website's Auth.jsx.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.register = false, this.from});

  /// Open on "Create account" instead of "Sign in"
  final bool register;

  /// Where to go after signing in (an app path such as /checkout). Home if not given.
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _login = TextEditingController(); // email (or username when signing in)
  final _mobile = TextEditingController();
  final _password = TextEditingController();

  late bool _register = widget.register;
  bool _showPassword = false;
  bool _busy = false;
  bool _triedSubmit = false; // show field errors as you type only after the first attempt
  int _shakes = 0;

  // Screen entrance: header lines fade up, then the white panel rises. Plays once.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _login, _mobile, _password]) {
      c.addListener(() => setState(() {})); // enables the button and updates the strength meter
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _login, _mobile, _password]) {
      c.dispose();
    }
    _intro.dispose();
    super.dispose();
  }

  bool get _ready => _register
      ? [_name, _login, _mobile, _password].every((c) => c.text.trim().isNotEmpty)
      : _login.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _switchMode(bool register) {
    if (register == _register) return;
    setState(() {
      _register = register;
      _triedSubmit = false;
    });
    _form.currentState?.reset(); // clear old error messages; typed text stays
  }

  void _leave() => context.go(_safeFrom ?? '/');

  /// Only app paths, never a full URL
  String? get _safeFrom {
    final f = widget.from;
    return f != null && f.startsWith('/') && !f.startsWith('//') && !f.startsWith('/login') ? f : null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _triedSubmit = true);
    if (!_form.currentState!.validate()) return _shake();

    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authProvider.notifier);
    setState(() => _busy = true);
    try {
      final user = _register
          ? await auth.register(
              fullName: _name.text,
              email: _login.text,
              phone: _mobile.text,
              password: _password.text,
            )
          : await auth.signIn(_login.text, _password.text);
      TextInput.finishAutofillContext(); // lets the phone offer to save the password
      messenger.showSnackBar(SnackBar(
        content: Text(_register ? l.registeredWelcome(user.firstName) : l.signedInWelcome(user.firstName)),
      ));
      if (mounted) _leave();
    } on DioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e, fallback: 'Something went wrong'))));
      _shake();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _shake() {
    if (!MediaQuery.disableAnimationsOf(context)) setState(() => _shakes++);
  }

  void _forgotPassword() => showForgotPassword(context, email: _login.text.trim());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final soft = theme.colorScheme.onSurfaceVariant;
    final dark = theme.brightness == Brightness.dark;
    final panel = dark ? NmColors.darkSurface : NmColors.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: panel, // the white panel continues to the bottom of the screen
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                controller: _intro,
                register: _register,
                onBack: _leave,
                onSkip: _leave,
              ),
              // White panel sliding up over the green header
              Transform.translate(
                offset: const Offset(0, -NmRadius.panel),
                child: Entrance(
                  controller: _intro,
                  delayMs: 150,
                  distance: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(NmRadius.panel)),
                    ),
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + MediaQuery.paddingOf(context).bottom),
                    child: _Shake(
                      shakes: _shakes,
                      child: Form(
                        key: _form,
                        autovalidateMode: _triedSubmit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ModeToggle(
                                register: _register,
                                signInLabel: l.tabSignIn,
                                registerLabel: l.tabCreateAccount,
                                onChanged: _busy ? null : _switchMode,
                              ),
                              const SizedBox(height: 24),
                              ..._fields(l, text),
                              if (!_register)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy ? null : _forgotPassword,
                                    child: Text(l.forgotPassword, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                              const SizedBox(height: 8),
                              _CtaButton(
                                label: _register ? l.tabCreateAccount : l.tabSignIn,
                                busy: _busy,
                                onPressed: _ready && !_busy ? _submit : null,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(_register ? l.haveAccount : l.newToNirmalMart, style: text.bodyMedium?.copyWith(color: soft)),
                                  TextButton(
                                    onPressed: _busy ? null : () => _switchMode(!_register),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                                    child: Text(_register ? l.tabSignIn : l.createAnAccount,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              if (_register) ...[
                                const SizedBox(height: 6),
                                Text(l.termsNote, textAlign: TextAlign.center, style: text.bodySmall?.copyWith(height: 1.5)),
                              ],
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 15, color: soft.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(l.secureNote, style: text.bodySmall?.copyWith(color: soft.withValues(alpha: 0.8)))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _fields(AppLocalizations l, TextTheme text) => [
        // Full name (create account only)
        _Reveal(
          visible: _register,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _name,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [_Cleaner(Validate.cleanName)],
              decoration: InputDecoration(
                labelText: l.fieldFullName,
                hintText: l.hintFullName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => _register && !Validate.isName(v ?? '') ? l.errName : null,
            ),
          ),
        ),
        TextFormField(
          controller: _login,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          autofillHints: _register ? const [AutofillHints.email] : const [AutofillHints.username, AutofillHints.email],
          decoration: InputDecoration(
            labelText: _register ? l.fieldEmail : l.fieldEmailOrUsername,
            hintText: l.hintEmail,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (_register) return Validate.isEmail(s) ? null : l.errEmail;
            return s.length >= 3 ? null : l.errLogin; // email, or a staff username
          },
        ),
        const SizedBox(height: 16),
        // Mobile (create account only) — required, same rule as the website
        _Reveal(
          visible: _register,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _mobile,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [_Cleaner(Validate.cleanMobile)],
              decoration: InputDecoration(
                labelText: l.fieldMobile,
                hintText: l.hintMobile,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_iphone_rounded),
                      const SizedBox(width: 6),
                      Text('+91', style: text.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 48),
              ),
              validator: (v) => _register && !Validate.isMobile(v ?? '') ? l.errMobile : null,
            ),
          ),
        ),
        TextFormField(
          controller: _password,
          enabled: !_busy,
          obscureText: !_showPassword,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _ready && !_busy ? _submit() : null,
          autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
          decoration: InputDecoration(
            labelText: l.fieldPassword,
            hintText: _register ? l.hintNewPassword : l.hintPassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _showPassword ? l.hidePassword : l.showPassword,
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (v) {
            final p = v ?? '';
            if (p.isEmpty) return l.errPasswordEmpty;
            if (_register && p.length < Validate.minPassword) return l.errPasswordShort;
            return null;
          },
        ),
        _Reveal(visible: _register && _password.text.isNotEmpty, child: _StrengthMeter(password: _password.text)),
      ];
}

/// Green top section: back / skip, logo, title and subtitle, with soft decorative circles behind
class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.register, required this.onBack, required this.onSkip});

  final AnimationController controller;
  final bool register;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? NmColors.brandDark : NmColors.brand;

    Widget up(int delay, Widget child) => Entrance(controller: controller, delayMs: delay, child: child);

    return Container(
      color: green,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative circles
          Positioned(right: -70, top: -50, child: _Blob(size: 240, color: Colors.white.withValues(alpha: 0.07))),
          Positioned(right: 40, top: 120, child: _Blob(size: 70, color: NmColors.gold.withValues(alpha: 0.22))),
          Positioned(left: -60, bottom: -10, child: _Blob(size: 170, color: Colors.white.withValues(alpha: 0.05))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, NmRadius.panel + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        tooltip: l.authBack,
                        onPressed: onBack,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(l.authSkip, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        up(0, const _LogoBadge()),
                        const SizedBox(height: 22),
                        // Title and subtitle cross-fade when switching mode
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          layoutBuilder: (current, previous) =>
                              Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                          child: Column(
                            key: ValueKey(register),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              up(
                                80,
                                Text(
                                  register ? l.registerTitle : l.loginTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              up(
                                140,
                                Text(
                                  register ? l.registerSub : l.loginSub,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        up(
                          200,
                          const Text(
                            'ट्रेंडिंग गॅझेट्स, उत्तम किमतीत',
                            style: TextStyle(color: NmColors.goldSoft, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// Logo in a white rounded tile with the store name beside it
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: SvgPicture.asset('assets/images/logo-mark.svg', semanticsLabel: 'Nirmal Mart'),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text.rich(
            TextSpan(text: 'NIRMAL ', children: [TextSpan(text: 'MART', style: TextStyle(color: NmColors.gold))]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }
}

/// Pill switch: a white thumb slides between "Sign in" and "Create account"
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.register, required this.signInLabel, required this.registerLabel, this.onChanged});

  final bool register;
  final String signInLabel;
  final String registerLabel;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);
    final track = dark ? const Color(0xFF22252B) : NmColors.muted;
    final thumb = dark ? NmColors.darkBackground : Colors.white;

    Widget option(bool value, String label) {
      final on = register == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.labelLarge!.copyWith(
                  fontSize: 14.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(999)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: still ? Duration.zero : const Duration(milliseconds: 280),
            curve: NmMotion.sheetCurve,
            alignment: register ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: thumb,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
              ),
            ),
          ),
          Row(children: [option(false, signInLabel), option(true, registerLabel)]),
        ],
      ),
    );
  }
}

/// Main button with a soft green glow while it can be pressed
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final on = onPressed != null;
    return PressScale(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NmRadius.button),
          boxShadow: [
            if (on) BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            // Faded (not grey) until the form is filled in, as in the design
            disabledBackgroundColor: primary.withValues(alpha: 0.45),
            disabledForegroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.onPrimary),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Applies a clean-up function to what's typed (e.g. digits only for mobile)
class _Cleaner extends TextInputFormatter {
  _Cleaner(this.clean);

  final String Function(String) clean;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = clean(newValue.text);
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
  }
}

/// Smoothly shows or hides a block (the create-account-only fields)
class _Reveal extends StatelessWidget {
  const _Reveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No animation wanted: swap instantly (AnimatedSize can't run with a zero duration)
    if (MediaQuery.disableAnimationsOf(context)) return visible ? child : const SizedBox(width: double.infinity);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: NmMotion.entranceCurve,
      alignment: Alignment.topCenter,
      child: visible ? child : const SizedBox(width: double.infinity),
    );
  }
}

/// Side-to-side shake when sign-in fails (as on the website)
class _Shake extends StatelessWidget {
  const _Shake({required this.shakes, required this.child});

  final int shakes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakes == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shakes),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(math.sin(t * math.pi * 5) * 10 * (1 - t), 0), child: child),
      child: child,
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  static const _colors = [NmColors.deal, Color(0xFFD97706), Color(0xFFFBBF24), NmColors.success];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = Validate.passwordStrength(password);
    final label = [l.strength0, l.strength1, l.strength2, l.strength3, l.strength4][s];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < s ? _colors[s - 1] : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text('$label · ${l.strengthHint}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
