import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/product_detail.dart';
import '../../core/catalog/recent_and_pincode.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/pincode_sheet.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';

const productGutter = 16.0;

// ───────────── Price ─────────────

class PriceBlock extends StatelessWidget {
  const PriceBlock({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = product;
    final t = Theme.of(context).textTheme;
    final faint = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(rupees(p.price), style: t.displaySmall!.copyWith(fontSize: 32, letterSpacing: -0.8, height: 1.1)),
            if (p.off > 0) ...[
              Text(rupees(p.mrp!), style: TextStyle(color: faint, fontSize: 16, decoration: TextDecoration.lineThrough)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: NmColors.deal, borderRadius: BorderRadius.circular(8)),
                child: Text(l.offTag(p.off), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(text: l.inclusiveTaxes, children: [
            if (p.off > 0) ...[
              const TextSpan(text: ' · '),
              TextSpan(text: l.youSave(rupees(p.mrp! - p.price)), style: const TextStyle(color: NmColors.success, fontWeight: FontWeight.w700)),
            ],
          ]),
          style: TextStyle(color: faint, fontSize: 12.5),
        ),
      ],
    );
  }
}

// ───────────── Stock ─────────────

/// Red "Hurry — only 5 left" bar at 10 or fewer, a green "In stock" line otherwise
class StockLine extends StatelessWidget {
  const StockLine({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (stock <= 0) {
      return _Pill(icon: Icons.remove_shopping_cart_outlined, text: l.outOfStock, color: NmColors.deal);
    }
    if (stock > 10) {
      return _Pill(icon: Icons.check_circle_outline_rounded, text: l.inStock, color: NmColors.success);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF341B1A) : const Color(0xFFFFF5F3),
        border: Border.all(color: dark ? const Color(0xFF5A2A26) : const Color(0xFFF7D9D3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🔥 ${l.hurryOnlyLeft(stock)}', style: const TextStyle(color: NmColors.deal, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ((11 - stock) / 10).clamp(0.15, 0.95), // fewer left = fuller bar
              minHeight: 6,
              backgroundColor: NmColors.deal.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(NmColors.deal),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.5))),
      ]);
}

// ───────────── Quantity ─────────────

class QuantityRow extends StatelessWidget {
  const QuantityRow({super.key, required this.value, required this.max, required this.onChanged});

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget btn(IconData icon, String tip, int to, bool enabled) => IconButton(
          tooltip: tip,
          onPressed: enabled ? () => onChanged(to) : null,
          icon: Icon(icon, color: enabled ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4)),
        );
    return Row(
      children: [
        Expanded(child: Text(l.quantity, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, fontSize: 15))),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: dark ? NmColors.darkLine : NmColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            btn(Icons.remove_rounded, l.removeOne, value - 1, value > 1),
            Semantics(
              label: '${l.quantity} $value',
              excludeSemantics: true,
              child: SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            btn(Icons.add_rounded, l.addOne, value + 1, value < max),
          ]),
        ),
      ],
    );
  }
}

// ───────────── Benefits ─────────────

class BenefitTiles extends StatelessWidget {
  const BenefitTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.local_shipping_outlined, l.benefitDelivery),
      (Icons.autorenew_rounded, l.benefitReturns),
      (Icons.verified_user_outlined, l.benefitSecure),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                decoration: BoxDecoration(color: dark ? NmColors.darkSurface : const Color(0xFFF6F8F4), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Icon(items[i].$1, color: scheme.primary, size: 24),
                  const SizedBox(height: 6),
                  Text(items[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────── Delivery ─────────────

/// Uses the pincode saved on Home, so the date shows straight away; Change opens the pincode sheet
class DeliveryCard extends ConsumerWidget {
  const DeliveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pin = ref.watch(pincodeProvider);
    final check = pin == null ? null : ref.watch(deliveryCheckProvider(pin));
    final result = check?.value;
    final Widget sub;
    if (pin == null) {
      sub = Text(l.deliveryEnterPin, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5));
    } else if (result == null) {
      sub = Text(l.deliveryChecking, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5));
    } else if (result.date != null) {
      sub = Text.rich(
        TextSpan(text: '${l.deliveryGetItBy} ', children: [
          TextSpan(text: result.date, style: const TextStyle(color: NmColors.success, fontWeight: FontWeight.w800)),
        ]),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
      );
    } else {
      sub = Text(l.pincodeUnserviceable, style: const TextStyle(color: NmColors.deal, fontSize: 12.5, fontWeight: FontWeight.w600));
    }
    return _Card(
      onTap: () => showPincodeSheet(context),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.location_on_outlined, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pin == null ? l.deliveryCheckTitle : l.deliveringTo(pin), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            const SizedBox(height: 2),
            sub,
          ]),
        ),
        Text(pin == null ? l.pincodeCheck : l.change, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ───────────── About this product ─────────────

/// Description with an English / मराठी switch; Highlights and Specifications fold open, shown only when filled in
class AboutSection extends StatefulWidget {
  const AboutSection({super.key, required this.detail});

  final ProductDetail detail;

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool? _marathi; // null = follow the app's language

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.detail;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final appMarathi = Localizations.localeOf(context).languageCode == 'mr';
    final marathi = d.hasMarathiDescription && (_marathi ?? appMarathi);
    final text = marathi ? d.descriptionMr! : (d.description?.isNotEmpty ?? false) ? d.description! : (d.descriptionMr ?? '');
    final hasAny = text.isNotEmpty || d.highlights.isNotEmpty || d.specs.isNotEmpty;
    if (!hasAny) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text(l.aboutProduct, style: t.titleLarge!.copyWith(fontSize: 18))),
          if (d.hasMarathiDescription && (d.description?.isNotEmpty ?? false))
            _LangSwitch(marathi: marathi, onChanged: (v) => setState(() => _marathi = v)),
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(text, style: t.bodyLarge!.copyWith(fontSize: 14.5, height: 1.55, color: scheme.onSurface.withValues(alpha: 0.85))),
        ],
        if (d.highlights.isNotEmpty || d.specs.isNotEmpty) const SizedBox(height: 8),
        if (d.highlights.isNotEmpty)
          _Fold(
            title: l.highlights,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final h in d.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_rounded, size: 17, color: scheme.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(h, style: t.bodyMedium!.copyWith(height: 1.4))),
                    ]),
                  ),
              ],
            ),
          ),
        if (d.specs.isNotEmpty)
          _Fold(
            title: l.specifications,
            child: Column(children: [
              for (final e in d.specs.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: Text(e.key, style: t.bodyMedium!.copyWith(color: scheme.onSurfaceVariant))),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: Text(e.value, style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600))),
                  ]),
                ),
            ]),
          ),
      ],
    );
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.marathi, required this.onChanged});

  final bool marathi;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    Widget opt(String label, bool value) => Semantics(
          button: true,
          selected: marathi == value,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: marathi == value ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [if (marathi == value) const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: marathi == value ? scheme.onSurface : scheme.onSurfaceVariant)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: dark ? const Color(0xFF22252B) : NmColors.muted, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [opt('English', false), opt('मराठी', true)]),
    );
  }
}

class _Fold extends StatefulWidget {
  const _Fold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                child: Row(children: [
                  Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: still ? Duration.zero : const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ]),
              ),
            ),
          ),
          if (still)
            if (_open) Padding(padding: const EdgeInsets.only(bottom: 10), child: widget.child) else const SizedBox.shrink()
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open ? Padding(padding: const EdgeInsets.only(bottom: 10), child: widget.child) : const SizedBox(width: double.infinity),
            ),
        ],
      ),
    );
  }
}

// ───────────── Ratings & reviews ─────────────

class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.product, required this.from});

  final Product product;

  /// This page's address, so Sign in comes back here
  final String from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final signedIn = ref.watch(authProvider.select((a) => a.value != null));
    final summary = ref.watch(reviewsProvider(product.id)).value;
    final count = summary?.count ?? product.ratingCount;
    final average = summary?.average ?? product.rating;

    final Widget action = signedIn
        ? (summary?.canReview ?? false)
            ? OutlinedButton(
                onPressed: () => showWriteReview(context, product),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: BorderSide(color: scheme.primary, width: 1.5),
                  foregroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                child: Text(l.writeReview),
              )
            : const SizedBox.shrink()
        : TextButton(
            onPressed: () => context.push('/login?from=${Uri.encodeComponent(from)}'),
            child: Text(l.signInToReview, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          );

    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.ratingsReviews, style: t.titleLarge!.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          if (count == 0) ...[
            _Stars(value: 0, size: 20),
            const SizedBox(height: 4),
            Text(l.noReviewsYet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(l.noReviewsBody, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: action),
          ]
          else ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Column(children: [
                Text(average.toStringAsFixed(1), style: t.displaySmall!.copyWith(fontSize: 36, height: 1)),
                const SizedBox(height: 4),
                _Stars(value: average, size: 15),
                const SizedBox(height: 2),
                Text(l.reviewsCount(count), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ]),
              const SizedBox(width: 18),
              if (summary != null)
                Expanded(
                  child: Column(children: [
                    for (var s = 5; s >= 1; s--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          SizedBox(width: 12, child: Text('$s', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
                          const Icon(Icons.star_rounded, size: 12, color: NmColors.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: summary.count == 0 ? 0 : summary.distribution[s]! / summary.count,
                                minHeight: 6,
                                backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation(NmColors.gold),
                              ),
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ),
            ]),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: action),
            for (final r in (summary?.reviews ?? const <Review>[]).take(5)) _ReviewTile(review: r),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.size});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          value >= i - 0.25 ? Icons.star_rounded : (value >= i - 0.75 ? Icons.star_half_rounded : Icons.star_rounded),
          size: size,
          color: value >= i - 0.75 ? NmColors.gold : empty,
        ),
    ]);
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = review;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(r.userName.isEmpty ? '?' : r.userName[0].toUpperCase(),
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Row(children: [
                _Stars(value: r.rating.toDouble(), size: 13),
                if (r.verified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, size: 13, color: NmColors.success),
                  const SizedBox(width: 2),
                  Flexible(child: Text(l.verifiedPurchase, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NmColors.success, fontSize: 11, fontWeight: FontWeight.w700))),
                ],
              ]),
            ]),
          ),
          if (r.createdAt != null) Text(DateFormat('d MMM y').format(r.createdAt!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
        ]),
        if (r.title?.isNotEmpty ?? false) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.title!, style: const TextStyle(fontWeight: FontWeight.w700))),
        if (r.comment?.isNotEmpty ?? false)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.comment!, style: TextStyle(height: 1.45, color: scheme.onSurface.withValues(alpha: 0.85)))),
      ]),
    );
  }
}

Future<void> showWriteReview(BuildContext context, Product product) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WriteReviewSheet(product: product),
    );

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.product});

  final Product product;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 0;
  final _title = TextEditingController();
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final l = AppLocalizations.of(context);
    if (_rating == 0) return setState(() => _error = l.reviewPickStars);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).dio.post('/products/${widget.product.id}/reviews', data: {
        'rating': _rating,
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        if (_comment.text.trim().isNotEmpty) 'comment': _comment.text.trim(),
      });
      ref.invalidate(reviewsProvider(widget.product.id));
      ref.invalidate(productDetailProvider(widget.product.slug));
      if (!mounted) return;
      Navigator.of(context).pop();
      showNmSnack(context, l.reviewThanks);
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
    final labels = [l.star1, l.star2, l.star3, l.star4, l.star5];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.writeReview, style: t.headlineSmall!.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text(widget.product.nameIn(Localizations.localeOf(context)), style: t.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var s = 1; s <= 5; s++)
                IconButton(
                  tooltip: labels[s - 1],
                  iconSize: 38,
                  onPressed: () => setState(() {
                    _rating = s;
                    _error = null;
                  }),
                  icon: Icon(s <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: s <= _rating ? NmColors.gold : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ]),
            Text(_rating == 0 ? l.reviewTapStars : labels[_rating - 1],
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: _rating == 0 ? Theme.of(context).colorScheme.onSurfaceVariant : NmColors.gold)),
            const SizedBox(height: 16),
            TextField(controller: _title, maxLength: 255, decoration: InputDecoration(labelText: l.reviewTitle, counterText: '')),
            const SizedBox(height: 12),
            TextField(controller: _comment, maxLength: 3000, minLines: 3, maxLines: 6, decoration: InputDecoration(labelText: l.reviewComment, alignLabelWithHint: true, counterText: '')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _post,
              child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Text(l.postReview),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────── Loading ─────────────

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Skeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: 110, height: 22, radius: 99),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 24),
          SizedBox(height: 8),
          SkeletonBox(width: 160, height: 16),
          SizedBox(height: 20),
          SkeletonBox(width: 180, height: 32),
          SizedBox(height: 22),
          SkeletonBox(width: double.infinity, height: 60, radius: 14),
          SizedBox(height: 18),
          SkeletonBox(width: double.infinity, height: 84, radius: 16),
        ]),
      );
}
