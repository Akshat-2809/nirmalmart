import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/shop.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

Future<ShopFilters?> showShopFilters(BuildContext context, ShopFilters current) => showModalBottomSheet<ShopFilters>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FiltersSheet(initial: current),
    );

Future<ShopSort?> showShopSort(BuildContext context, ShopSort current) => showModalBottomSheet<ShopSort>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final labels = {
          ShopSort.newest: l.sortNewest,
          ShopSort.popular: l.sortPopular,
          ShopSort.priceLow: l.sortPriceLow,
          ShopSort.priceHigh: l.sortPriceHigh,
          ShopSort.discount: l.sortDiscount,
        };
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(l.sortBy, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
              ),
              RadioGroup<ShopSort>(
                groupValue: current,
                onChanged: (v) => Navigator.of(context).pop(v),
                child: Column(children: [
                  for (final e in labels.entries)
                    RadioListTile<ShopSort>(
                      value: e.key,
                      title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                ]),
              ),
            ]),
          ),
        );
      },
    );

/// Category, price (slider + quick buttons), brand and in-stock, with a live "Show N products" count
class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.initial});

  final ShopFilters initial;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late ShopFilters _f = widget.initial;
  RangeValues? _drag; // slider position while dragging (applied on release)

  static const _quick = [(null, 199), (null, 499), (null, 999), (1000, null)];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final facets = ref.watch(shopFacetsProvider(_f.category)).value;
    final count = ref.watch(shopCountProvider(_f));
    final shown = count.value;

    Widget heading(String s) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 9),
          child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        );

    // Slider runs from the cheapest to the dearest product, in ₹50 steps
    final lo = facets == null ? 0.0 : (facets.minPrice / 50).floor() * 50.0;
    final hi = facets == null ? 0.0 : math.max(lo + 50, (facets.maxPrice / 50).ceil() * 50.0);
    final current = _drag ??
        RangeValues(
          (_f.minPrice?.toDouble() ?? lo).clamp(lo, hi),
          (_f.maxPrice?.toDouble() ?? hi).clamp(lo, hi),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(children: [
            Expanded(child: Text(l.filters, style: t.headlineSmall!.copyWith(fontSize: 20))),
            TextButton(
              onPressed: () => setState(() {
                _f = _f.cleared();
                _drag = null;
              }),
              child: Text(l.clearAll, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cats.isNotEmpty) ...[
                heading(l.categoryLabel),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _Choice(
                    label: l.allProducts,
                    on: _f.category == null && !_f.trending,
                    onTap: () => setState(() => _f = ShopFilters(sort: _f.sort, inStock: _f.inStock)),
                  ),
                  for (final c in cats)
                    _Choice(
                      label: c.nameIn(locale),
                      on: _f.category == c.slug,
                      // brands and prices differ per category, so those reset
                      onTap: () => setState(() {
                        _f = ShopFilters(category: c.slug, sort: _f.sort, inStock: _f.inStock);
                        _drag = null;
                      }),
                    ),
                ]),
              ],
              heading(l.priceLabel),
              if (facets != null && hi > lo) ...[
                RangeSlider(
                  values: current,
                  min: lo,
                  max: hi,
                  divisions: math.max(1, ((hi - lo) / 50).round()),
                  labels: RangeLabels(rupees(current.start), rupees(current.end)),
                  onChanged: (v) => setState(() => _drag = v),
                  onChangeEnd: (v) => setState(() {
                    _drag = null;
                    _f = _f.copyWith(
                      minPrice: () => v.start <= lo ? null : v.start.round(),
                      maxPrice: () => v.end >= hi ? null : v.end.round(),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    Text(rupees(current.start), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(rupees(current.end), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (min, max) in _quick)
                  _Choice(
                    label: max != null ? l.under(rupees(max)) : '${rupees(min!)}+',
                    on: _f.minPrice == min && _f.maxPrice == max,
                    onTap: () => setState(() {
                      final on = _f.minPrice == min && _f.maxPrice == max;
                      _f = _f.copyWith(minPrice: () => on ? null : min, maxPrice: () => on ? null : max);
                    }),
                  ),
              ]),
              if (facets != null && facets.brands.isNotEmpty) ...[
                heading(l.brandLabel),
                for (final b in facets.brands)
                  CheckboxListTile(
                    value: _f.brands.contains(b),
                    onChanged: (v) => setState(() => _f = _f.copyWith(brands: v == true ? {..._f.brands, b} : ({..._f.brands}..remove(b)))),
                    title: Text(b, style: const TextStyle(fontWeight: FontWeight.w600)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                value: _f.inStock,
                onChanged: (v) => setState(() => _f = _f.copyWith(inStock: v)),
                title: Text(l.inStockOnly, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(widget.initial.cleared()),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(l.reset),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: shown == 0 ? null : () => Navigator.of(context).pop(_f),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(shown == null ? l.showResults : shown == 0 ? l.noProductsMatch : l.showProducts(shown)),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? scheme.primary.withValues(alpha: dark ? 0.22 : 0.12) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: on ? scheme.primary : (dark ? NmColors.darkLine : NmColors.line)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? (dark ? NmColors.brandOnDark : NmColors.brandDark) : scheme.onSurface)),
          ),
        ),
      ),
    );
  }
}
