import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/validate.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/product_card.dart' show showNmSnack;

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );

TextInputFormatter _clean(String Function(String) f) => TextInputFormatter.withFunction((o, n) {
      final v = f(n.text);
      return v == n.text ? n : TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
    });

Widget _padded(BuildContext context, Widget child) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: child),
    );

Widget _errorText(String? e) =>
    e == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 10), child: Text(e, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600)));

Widget _busyOr(bool busy, String label) =>
    busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Text(label);

// ───────────── Edit profile ─────────────

Future<void> showEditProfile(BuildContext context, AppUser user) => _sheet(context, _EditProfile(user: user));

class _EditProfile extends ConsumerStatefulWidget {
  const _EditProfile({required this.user});

  final AppUser user;

  @override
  ConsumerState<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<_EditProfile> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: Validate.cleanMobile(widget.user.phone ?? ''));
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).updateProfile(fullName: _name.text, phone: _phone.text.isEmpty ? null : _phone.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNmSnack(context, l.profileUpdated);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _padded(
      context,
      Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.editProfile, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l.fieldFullName, prefixIcon: const Icon(Icons.person_outline_rounded)),
            textCapitalization: TextCapitalization.words,
            inputFormatters: [_clean(Validate.cleanName)],
            validator: (v) => Validate.isName(v ?? '') ? null : l.errName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            decoration: InputDecoration(labelText: l.fieldMobile, prefixIcon: const Icon(Icons.phone_outlined), prefixText: '+91 '),
            keyboardType: TextInputType.phone,
            inputFormatters: [_clean(Validate.cleanMobile)],
            validator: (v) => (v ?? '').isEmpty || Validate.isMobile(v!) ? null : l.errMobile,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.user.email,
            enabled: false,
            decoration: InputDecoration(labelText: l.fieldEmail, prefixIcon: const Icon(Icons.mail_outline_rounded), helperText: l.emailCantChange),
          ),
          _errorText(_error),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: _busyOr(_busy, l.saveChanges)),
        ]),
      ),
    );
  }
}

// ───────────── Change password ─────────────

Future<void> showChangePassword(BuildContext context) => _sheet(context, const _ChangePassword());

class _ChangePassword extends ConsumerStatefulWidget {
  const _ChangePassword();

  @override
  ConsumerState<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<_ChangePassword> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNmSnack(context, l.passwordUpdated);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _show ? l.hidePassword : l.showPassword,
            onPressed: () => setState(() => _show = !_show),
            icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          ),
        );
    return _padded(
      context,
      Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.changePassword, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _current,
            obscureText: !_show,
            autofillHints: const [AutofillHints.password],
            decoration: deco(l.currentPassword),
            validator: (v) => (v ?? '').isEmpty ? l.enterCurrentPassword : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _next,
            obscureText: !_show,
            autofillHints: const [AutofillHints.newPassword],
            decoration: deco(l.newPassword),
            validator: (v) => (v ?? '').length < Validate.minPassword ? l.errPasswordShort : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirm,
            obscureText: !_show,
            decoration: deco(l.confirmNewPassword),
            validator: (v) => v != _next.text ? l.passwordsDontMatch : null,
          ),
          _errorText(_error),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: _busyOr(_busy, l.updatePassword)),
        ]),
      ),
    );
  }
}

// ───────────── Delete account ─────────────

Future<void> showDeleteAccount(BuildContext context) => _sheet(context, const _DeleteAccount());

class _DeleteAccount extends ConsumerStatefulWidget {
  const _DeleteAccount();

  @override
  ConsumerState<_DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<_DeleteAccount> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.heavyImpact();
    try {
      await ref.read(authProvider.notifier).deleteAccount(_password.text);
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go('/');
      showNmSnack(context, l.accountDeleted);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _padded(
      context,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: NmColors.deal.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.delete_forever_outlined, color: NmColors.deal, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(l.deleteAccountQ, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final point in [l.deletePoint1, l.deletePoint2, l.deletePoint3])
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 7, right: 8), child: Icon(Icons.circle, size: 5)),
              Expanded(child: Text(point, style: const TextStyle(fontSize: 13.5, height: 1.45))),
            ]),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: dark ? const Color(0xFF22252B) : NmColors.muted, borderRadius: BorderRadius.circular(12)),
          child: Text(l.deleteKeepsOrders, style: TextStyle(fontSize: 12.5, height: 1.4, color: scheme.onSurface.withValues(alpha: 0.8))),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.deleteEnterPassword, prefixIcon: const Icon(Icons.lock_outline_rounded)),
        ),
        _errorText(_error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || _password.text.isEmpty ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: NmColors.deal, minimumSize: const Size.fromHeight(52)),
          child: _busyOr(_busy, l.deleteMyAccount),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.keepMyAccount)),
      ]),
    );
  }
}
