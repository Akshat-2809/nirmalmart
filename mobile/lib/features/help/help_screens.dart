import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/contact_sheet.dart';
import 'help_content.dart';

/// The help pages in the app's own design, in the app's language (English / मराठी)
enum HelpPage { faq, shipping, privacy, refunds, terms }

typedef _Content = HelpContent;

_Content _content(BuildContext context) => helpContent[Localizations.localeOf(context).languageCode == 'mr' ? 'mr' : 'en']!;

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.page, this.open});

  final HelpPage page;

  /// FAQ to open straight away (e.g. 'returns')
  final String? open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _content(context);
    final (title, intro, body) = switch (page) {
      HelpPage.faq => (l.faqTitle, c.faqIntro, _Faqs(faqs: c.faqs, open: open)),
      HelpPage.shipping => (l.shippingReturns, c.shippingIntro, _Shipping(c: c)),
      HelpPage.privacy => (l.privacyPolicy, c.privacyIntro, _Legal(sections: c.privacy)),
      HelpPage.refunds => (l.refundPolicy, c.refundsIntro, _Legal(sections: c.refunds)),
      HelpPage.terms => (l.termsOfUse, c.termsIntro, _Legal(sections: c.terms)),
    };
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: scheme.surface),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(intro, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45)),
          const SizedBox(height: 14),
          body,
          const SizedBox(height: 20),
          _StillStuck(page: page),
        ],
      ),
    );
  }
}

class _Faqs extends StatefulWidget {
  const _Faqs({required this.faqs, this.open});

  final List<Faq> faqs;
  final String? open;

  @override
  State<_Faqs> createState() => _FaqsState();
}

class _FaqsState extends State<_Faqs> {
  Widget _answer(Faq f, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(f.a, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8), fontSize: 13.5, height: 1.5)),
      );

  late final Set<String> _open = {widget.faqs.any((f) => f.id == widget.open) ? widget.open! : widget.faqs.first.id};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);
    return Column(children: [
      for (final f in widget.faqs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _open.contains(f.id) ? scheme.primary.withValues(alpha: 0.5) : (dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Semantics(
                button: true,
                expanded: _open.contains(f.id),
                child: InkWell(
                  onTap: () => setState(() => _open.contains(f.id) ? _open.remove(f.id) : _open.add(f.id)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(children: [
                      Expanded(child: Text(f.q, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                      AnimatedRotation(
                        turns: _open.contains(f.id) ? 0.5 : 0,
                        duration: still ? Duration.zero : const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more_rounded, color: _open.contains(f.id) ? scheme.primary : scheme.onSurfaceVariant),
                      ),
                    ]),
                  ),
                ),
              ),
              // with animations turned off (accessibility), no AnimatedSize: it can't take a zero duration
              if (still)
                if (_open.contains(f.id)) _answer(f, scheme) else const SizedBox.shrink()
              else
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _open.contains(f.id) ? _answer(f, scheme) : const SizedBox(width: double.infinity),
                ),
            ]),
          ),
        ),
    ]);
  }
}

IconData _icon(String name) => switch (name) {
      'Clock' => Icons.schedule_rounded,
      'Truck' => Icons.local_shipping_outlined,
      'MapPin' => Icons.location_on_outlined,
      'Package' => Icons.inventory_2_outlined,
      _ => Icons.info_outline_rounded,
    };

class _Shipping extends StatelessWidget {
  const _Shipping({required this.c});

  final _Content c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const stepIcons = [Icons.check_circle_outline_rounded, Icons.inventory_2_outlined, Icons.local_shipping_outlined, Icons.home_outlined];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final f in c.facts)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon(f.icon), color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                Text(f.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(f.body, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8), fontSize: 13, height: 1.45)),
              ]),
            ),
          ]),
        ),
      const SizedBox(height: 10),
      Text(c.stepsTitle, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
      const SizedBox(height: 12),
      for (var i = 0; i < c.steps.length; i++)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              child: Icon(stepIcons[i % stepIcons.length], color: Colors.white, size: 18),
            ),
            if (i < c.steps.length - 1) Container(width: 2, height: 22, color: scheme.primary.withValues(alpha: 0.3)),
          ]),
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(top: 7), child: Text(c.steps[i], style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
    ]);
  }
}

class _Legal extends StatelessWidget {
  const _Legal({required this.sections});

  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      for (var i = 0; i < sections.length; i++)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '${i + 1}. ', style: TextStyle(color: scheme.primary)),
                TextSpan(text: sections[i].title),
              ]),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            ),
            const SizedBox(height: 8),
            for (final p in sections[i].points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 7, right: 8), child: Icon(Icons.circle, size: 5, color: scheme.primary)),
                  Expanded(child: Text(p, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.82), fontSize: 13.5, height: 1.5))),
                ]),
              ),
          ]),
        ),
    ]);
  }
}

/// "Still have a question?" → WhatsApp or Call
class _StillStuck extends StatelessWidget {
  const _StillStuck({required this.page});

  final HelpPage page;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _content(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: dark ? NmColors.darkSurface : NmColors.muted, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.support_agent_rounded, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(page == HelpPage.shipping ? c.lateHelp : l.stillQuestion, style: const TextStyle(fontWeight: FontWeight.w600))),
        TextButton(onPressed: () => showContactSheet(context), child: Text(l.contactUsTitle)),
      ]),
    );
  }
}

/// Opens a help page inside the app
void openHelp(BuildContext context, HelpPage page) => context.push('/help/${page.name}');
