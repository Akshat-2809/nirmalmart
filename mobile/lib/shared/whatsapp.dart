import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Opens a WhatsApp chat with [number] (country code, no +) and a prefilled message.
/// Shows a short message if nothing on the phone can open it.
Future<void> openWhatsApp(BuildContext context, String number, String text) async {
  final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).whatsAppMissing;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
