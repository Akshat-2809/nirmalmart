import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'whatsapp.dart';

/// "Need help?" — asks WhatsApp, Email or Call, then opens that app.
/// [message] is typed into WhatsApp for them (e.g. with the order number).
Future<void> showContactSheet(BuildContext context, {String? message, String? emailSubject}) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      useSafeArea: true,
      isScrollControlled: true, // as tall as it needs, scrolling on short screens
      builder: (sheet) {
        final l = AppLocalizations.of(sheet);
        final scheme = Theme.of(sheet).colorScheme;
        Widget option({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) => Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Theme.of(sheet).brightness == Brightness.dark ? NmColors.darkLine : NmColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                  ]),
                ),
              ),
            );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.contactUsTitle, style: Theme.of(sheet).textTheme.headlineSmall!.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text(l.contactUsBody, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5)),
            const SizedBox(height: 16),
            option(
              icon: Icons.chat_rounded,
              color: const Color(0xFF128C4B),
              title: l.contactWhatsApp,
              subtitle: l.contactWhatsAppSub,
              onTap: () {
                Navigator.of(sheet).pop();
                openWhatsApp(context, AppConfig.supportWhatsApp, message ?? l.helpGeneral);
              },
            ),
            const SizedBox(height: 10),
            option(
              icon: Icons.mail_outline_rounded,
              color: const Color(0xFF8A5A00),
              title: l.contactEmail,
              subtitle: AppConfig.supportEmail,
              onTap: () async {
                Navigator.of(sheet).pop();
                final messenger = ScaffoldMessenger.of(context);
                final uri = Uri(
                  scheme: 'mailto',
                  path: AppConfig.supportEmail,
                  query: emailSubject == null ? null : 'subject=${Uri.encodeComponent(emailSubject)}',
                );
                final ok = await launchUrl(uri).catchError((_) => false);
                if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.emailFailed(AppConfig.supportEmail))));
              },
            ),
            const SizedBox(height: 10),
            option(
              icon: Icons.call_rounded,
              color: scheme.primary,
              title: l.contactCall,
              subtitle: AppConfig.supportPhoneDisplay,
              onTap: () async {
                Navigator.of(sheet).pop();
                final messenger = ScaffoldMessenger.of(context);
                final ok = await launchUrl(Uri(scheme: 'tel', path: AppConfig.supportPhone)).catchError((_) => false);
                if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.callFailed(AppConfig.supportPhoneDisplay))));
              },
            ),
          ]),
        );
      },
    );
