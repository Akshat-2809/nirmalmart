import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/tokens.dart';
import '../../core/validate.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/whatsapp.dart';

/// Forgot password: emails a reset link (it opens the website's "choose a new password" page),
/// with WhatsApp as a fallback. The answer is the same whether or not the email has an account.
Future<void> showForgotPassword(BuildContext context, {String email = ''}) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ForgotSheet(email: email),
    );

class _ForgotSheet extends ConsumerStatefulWidget {
  const _ForgotSheet({required this.email});

  final String email;

  @override
  ConsumerState<_ForgotSheet> createState() => _ForgotSheetState();
}

class _ForgotSheetState extends ConsumerState<_ForgotSheet> {
  late final _email = TextEditingController(text: widget.email.contains('@') ? widget.email : '');
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    if (!Validate.isEmail(_email.text)) return setState(() => _error = l.errEmail);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).dio.post('/auth/forgot-password', data: {'email': _email.text.trim()});
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_sent) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read_outlined, color: scheme.primary, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.checkYourEmail, style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(l.resetSentBody(_email.text.trim()), style: t.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.backToSignIn)),
            TextButton(onPressed: () => setState(() => _sent = false), child: Text(l.resendLink)),
          ] else ...[
            Text(l.forgotTitle, style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(l.forgotEmailBody, style: t.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(labelText: l.fieldEmail, prefixIcon: const Icon(Icons.mail_outline_rounded), errorText: _error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(l.sendResetLink),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                final e = _email.text.trim();
                openWhatsApp(context, AppConfig.supportWhatsApp, l.forgotWhatsAppText(e.isEmpty ? '—' : e));
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF128C4B)),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l.forgotNoEmailAccess),
            ),
          ],
          if (_error != null && _sent) Text(_error!, style: const TextStyle(color: NmColors.deal)),
        ]),
      ),
    );
  }
}
