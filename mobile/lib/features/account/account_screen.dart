import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/prefs.dart';
import '../../core/push/push.dart';
import '../../core/theme/tokens.dart';
import '../../core/wishlist/wishlist.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/product_card.dart' show showNmSnack;

import 'package:url_launcher/url_launcher.dart';

import '../../shared/contact_sheet.dart';
import '../help/help_screens.dart';
import 'account_sheets.dart';

/// Account tab: profile, orders, addresses, password, language, appearance, help, sign out and
/// delete account. Guests see Sign in / Create account with the same settings and help.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: user != null || dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            if (user != null) ...[_Header(user: user), const _Stats(), if (user.isAdmin) const _AdminNote(), const _MyStuff()] else const _GuestHeader(),
            const _Settings(),
            _Notifications(signedIn: user != null),
            const _Help(),
            if (user != null) const _AccountActions(),
            const _Version(),
          ],
        ),
      ),
    );
  }
}

// ───────────── Signed in ─────────────

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final initial = user.fullName.trim().isEmpty ? '?' : user.fullName.trim()[0].toUpperCase();
    final contact = [user.email, if (user.phone?.isNotEmpty ?? false) _mobile(user.phone!)].join(' · ');
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 12, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [NmColors.brand, NmColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NmColors.goldSoft,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
            ),
            child: Text(
              initial,
              style: const TextStyle(color: NmColors.brandDark, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showEditProfile(context, user),
            style: TextButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16), foregroundColor: Colors.white),
            child: Text(l.edit),
          ),
        ],
      ),
    );
  }
}

/// "98765 43210"
String _mobile(String p) => p.length == 10 ? '${p.substring(0, 5)} ${p.substring(5)}' : p;

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final orders = ref.watch(ordersProvider).value?.length;
    final wished = ref.watch(wishlistProvider).value?.length;
    final addresses = ref.watch(addressesProvider).value?.length;
    final tiles = [
      (Icons.receipt_long_outlined, orders, l.ordersTile, '/account/orders'),
      (Icons.favorite_border_rounded, wished, l.tabWishlist, '/wishlist'),
      (Icons.location_on_outlined, addresses, l.addressesTile, '/account/addresses'),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: scheme.surface,
                  elevation: 3,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => tiles[i].$4 == '/wishlist' ? context.go('/wishlist') : context.push(tiles[i].$4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Column(
                        children: [
                          Icon(tiles[i].$1, color: scheme.primary),
                          const SizedBox(height: 2),
                          Text(
                            tiles[i].$2 == null ? '–' : '${tiles[i].$2}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                          Text(
                            tiles[i].$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyStuff extends ConsumerWidget {
  const _MyStuff();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final orders = ref.watch(ordersProvider).value ?? const <Order>[];
    final unpaid = orders.where((o) => o.awaitingPayment).toList();
    final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
    final main = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    return Transform.translate(
      offset: const Offset(0, -10),
      child: _Group(
        title: l.myStuffCaps,
        children: [
          _Row(
            icon: Icons.receipt_long_outlined,
            title: l.myOrders,
            subtitle: unpaid.isEmpty ? null : l.awaitingPaymentCount(unpaid.length),
            trailing: unpaid.isEmpty ? null : _Tag(text: l.payAmount(rupees(unpaid.first.total))),
            onTap: () => context.push('/account/orders'),
          ),
          _Row(
            icon: Icons.location_on_outlined,
            title: l.savedAddresses,
            subtitle: main == null ? l.noAddressesYet : '${_labelName(l, main.label)} · ${main.city} ${main.pincode}',
            onTap: () => context.push('/account/addresses'),
          ),
          _Row(icon: Icons.lock_outline_rounded, title: l.changePassword, onTap: () => showChangePassword(context)),
        ],
      ),
    );
  }
}

String _labelName(AppLocalizations l, String label) => switch (label.toLowerCase()) {
  'work' => l.labelWork,
  'other' => l.labelOther,
  _ => l.labelHome,
};

// ───────────── Guest ─────────────

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final perks = [
      (Icons.local_shipping_outlined, l.perkTrack),
      (Icons.favorite_border_rounded, l.perkSync),
      (Icons.bolt_rounded, l.perkFaster),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 28, 16, 0),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.person_outline_rounded, size: 44, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            l.accountHello,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l.accountGuestBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/login?from=${Uri.encodeComponent('/account')}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l.tabSignIn),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/login?mode=register&from=${Uri.encodeComponent('/account')}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: scheme.primary, width: 1.5),
                    foregroundColor: scheme.primary,
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(l.tabCreateAccount)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? NmColors.darkSurface : const Color(0xFFF6F8F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final (icon, text) in perks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── Settings, help, sign out ─────────────

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final marathi = Localizations.localeOf(context).languageCode == 'mr';
    final mode = ref.watch(themeModeProvider);
    return _Group(
      title: l.settingsCaps,
      children: [
        _Row(
          icon: Icons.translate_rounded,
          title: l.language,
          trailing: _Segments<bool>(
            value: marathi,
            options: const [(false, 'English'), (true, 'मराठी')],
            onChanged: (v) => ref.read(localeProvider.notifier).set(Locale(v ? 'mr' : 'en')),
          ),
        ),
        _Row(
          icon: Icons.dark_mode_outlined,
          title: l.appearance,
          trailing: _Segments<ThemeMode>(
            value: mode,
            options: [(ThemeMode.system, l.themeAuto), (ThemeMode.light, l.themeLight), (ThemeMode.dark, l.themeDark)],
            onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
          ),
        ),
      ],
    );
  }
}

/// Order updates (signed in only) and offers. Off when Android blocks notifications for the app.
class _Notifications extends ConsumerWidget {
  const _Notifications({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final push = ref.watch(pushProvider);
    final c = ref.read(pushProvider.notifier);
    Future<void> toggle(Future<bool> Function(bool) set, bool on) async {
      final ok = await set(on);
      if (!ok && context.mounted) showNmSnack(context, l.notifBlocked);
    }

    Widget sw(bool value, Future<bool> Function(bool) set) =>
        Switch(value: push.allowed && value, onChanged: (v) => toggle(set, v));
    return _Group(
      title: l.notificationsCaps,
      children: [
        if (signedIn)
          _Row(
            icon: Icons.local_shipping_outlined,
            title: l.notifOrders,
            subtitle: l.notifOrdersSub,
            trailing: sw(push.orders, c.setOrders),
          ),
        _Row(
          icon: Icons.local_offer_outlined,
          title: l.notifOffers,
          subtitle: l.notifOffersSub,
          trailing: sw(push.offers, c.setOffers),
        ),
      ],
    );
  }
}

class _Help extends StatelessWidget {
  const _Help();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Group(
      title: l.helpCaps,
      children: [
        _Row(
          icon: Icons.support_agent_rounded,
          title: l.contactUsTitle,
          subtitle: l.contactUsSub,
          onTap: () => showContactSheet(context),
        ),
        _Row(icon: Icons.help_outline_rounded, title: l.faqs, onTap: () => openHelp(context, HelpPage.faq)),
        _Row(icon: Icons.local_shipping_outlined, title: l.shippingReturns, onTap: () => openHelp(context, HelpPage.shipping)),
        _Row(icon: Icons.policy_outlined, title: l.privacyPolicy, onTap: () => openHelp(context, HelpPage.privacy)),
      _Row(icon: Icons.currency_rupee_rounded, title: l.refundPolicy, onTap: () => openHelp(context, HelpPage.refunds)),
        _Row(icon: Icons.description_outlined, title: l.termsOfUse, onTap: () => openHelp(context, HelpPage.terms)),
        const _Socials(),
      ],
    );
  }
}

/// Staff signed in on the phone: the app is for shopping only; store controls are on the website
class _AdminNote extends StatelessWidget {
  const _AdminNote();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C2838) : const Color(0xFFE6EEF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.admin_panel_settings_outlined, color: scheme.onSurface),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.adminNoteTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            Text(l.adminNoteBody, style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.8))),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('${AppConfig.siteUrl}/admin'), mode: LaunchMode.externalApplication),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4), minimumSize: const Size(0, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('${l.adminNoteOpen} ↗'),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Follow us: Instagram, Facebook, YouTube (opens their app if installed)
class _Socials extends StatelessWidget {
  const _Socials();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final links = [
      ('Instagram', Icons.photo_camera_outlined, const Color(0xFFC13584), AppConfig.instagram),
      ('Facebook', Icons.facebook_rounded, const Color(0xFF1877F2), AppConfig.facebook),
      ('YouTube', Icons.smart_display_rounded, const Color(0xFFFF0000), AppConfig.youtube),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.followUs, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          Text(l.followUsSub, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (name, icon, color, url) in links) ...[
                Expanded(
                  child: Semantics(
                    button: true,
                    label: name,
                    excludeSemantics: true,
                    child: Material(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          ).catchError((_) => false);
                          if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.linkFailed)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              Icon(icon, color: color),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  name,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (name != 'YouTube') const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends ConsumerWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _Group(
      title: l.accountCaps,
      children: [
        _Row(
          icon: Icons.logout_rounded,
          title: l.signOut,
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(l.signOutQ),
                content: Text(l.signOutBody),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
                  FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.signOut)),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(authProvider.notifier).signOut();
              if (!context.mounted) return;
              showNmSnack(context, l.signedOut);
              // straight to Sign in / Create account; Back returns to the (now guest) Account tab
              context.push('/login?from=${Uri.encodeComponent('/account')}');
            }
          },
        ),
        _Row(
          icon: Icons.delete_forever_outlined,
          title: l.deleteAccount,
          subtitle: l.deleteAccountSub,
          danger: true,
          onTap: () => showDeleteAccount(context),
        ),
      ],
    );
  }
}

class _Version extends StatelessWidget {
  const _Version();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform().catchError((_) => PackageInfo(appName: '', packageName: '', version: '', buildNumber: '')),
    builder: (context, s) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Nirmal Mart${(s.data?.version.isNotEmpty ?? false) ? ' · ${AppLocalizations.of(context).version(s.data!.version)}' : ''}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

// ───────────── Building blocks ─────────────

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final line = dark ? NmColors.darkLine : const Color(0xFFF0F0EC);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              title,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: scheme.onSurfaceVariant),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: line, indent: 14, endIndent: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = danger ? NmColors.deal : scheme.onSurface;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger ? NmColors.deal.withValues(alpha: 0.1) : (dark ? const Color(0xFF22252B) : NmColors.muted),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: danger ? NmColors.deal : scheme.onSurface.withValues(alpha: 0.85)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: color),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          // switches shrink rather than overflow on narrow phones with large text
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: trailing!),
            ),
          ],
          if (onTap != null) Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF3A2F17) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(color: dark ? NmColors.goldSoft : const Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// A small pill switch (English | मराठी, Auto | Light | Dark)
class _Segments<T> extends StatelessWidget {
  const _Segments({required this.value, required this.options, required this.onChanged});

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: dark ? const Color(0xFF22252B) : NmColors.muted, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in options)
            Semantics(
              button: true,
              selected: v == value,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: v == value ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [if (v == value) const BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: v == value ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
