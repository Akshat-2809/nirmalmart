import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog/catalog.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/search.dart';
import '../../core/catalog/smart_search.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/press_scale.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';
import '../home/home_sections.dart' show ProductPair, CategoryTiles;

/// Search: recent searches, popular products and categories before typing; instant suggestions while
/// typing; full results with sort and filters. Works in English and Marathi, and also finds Marathi
/// typed in English letters ("batli" → बाटली), other forms of a Marathi word and spelling slips.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initial});

  /// Opens straight on the results for this search (e.g. /search?q=torch)
  final String? initial;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _text = TextEditingController(text: widget.initial ?? '');
  final _focus = FocusNode();
  Timer? _debounce;
  String _live = ''; // what suggestions are shown for (settles 300 ms after typing stops)
  SearchQuery? _query; // the submitted search, with its sort and filters

  @override
  void initState() {
    super.initState();
    final first = widget.initial?.trim() ?? '';
    if (first.isNotEmpty) {
      _query = SearchQuery(first);
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(recentSearchesProvider.notifier).add(first));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
    }
    _text.addListener(_changed);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    final t = _text.text.trim();
    if (_query != null && t != _query!.text) setState(() => _query = null); // editing: back to suggestions
    _debounce?.cancel();
    if (t.isEmpty) {
      if (_live.isNotEmpty) setState(() => _live = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _live = t);
    });
    setState(() {}); // shows/hides the clear button
  }

  void _submit(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    _debounce?.cancel();
    _text.removeListener(_changed);
    _text.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    _text.addListener(_changed);
    FocusScope.of(context).unfocus();
    ref.read(recentSearchesProvider.notifier).add(t);
    setState(() {
      _live = t;
      _query = SearchQuery(t);
    });
  }

  void _fill(String name) {
    _text.value = TextEditingValue(text: name, selection: TextSelection.collapsed(offset: name.length));
    _focus.requestFocus();
  }

  void _clear() {
    _text.clear();
    _focus.requestFocus();
    setState(() {
      _query = null;
      _live = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = _text.text.trim();
    final Widget body;
    if (_query != null) {
      body = _Results(
        query: _query!,
        onChange: (q) => setState(() => _query = q),
        onSearch: _submit,
      );
    } else if (typed.isNotEmpty) {
      body = _Suggestions(typed: typed, live: _live, onSeeAll: () => _submit(typed), onFill: _fill);
    } else {
      body = _Start(onSearch: _submit);
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            _SearchBar(controller: _text, focus: _focus, onSubmit: _submit, onClear: _clear),
            // the search bar already makes room for the status bar
            Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: body)),
          ],
        ),
      ),
    );
  }
}

// ───────────── Search box ─────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.focus, required this.onSubmit, required this.onClear});

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)))),
        padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 6, 12, 10),
        child: Row(children: [
          IconButton(
            tooltip: l.authBack,
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
              maxLength: 100,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: l.searchHint,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(tooltip: l.clearSearch, onPressed: onClear, icon: const Icon(Icons.cancel_rounded, size: 20)),
                enabledBorder: border(Colors.transparent),
                focusedBorder: border(scheme.primary, 1.6),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ───────────── Before typing ─────────────

class _Start extends ConsumerWidget {
  const _Start({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final recent = ref.watch(recentSearchesProvider);
    final trending = ref.watch(trendingProductsProvider).value ?? const <Product>[];
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        if (recent.isNotEmpty) ...[
          _Heading(text: l.recentSearches, action: l.clearAll, onAction: () => ref.read(recentSearchesProvider.notifier).clear()),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in recent) _HistoryChip(text: r, onTap: () => onSearch(r)),
          ]),
          const SizedBox(height: 24),
        ],
        if (trending.isNotEmpty) ...[
          _Heading(text: '🔥 ${l.popularNow}'),
          _PopularList(products: trending.take(5).toList()),
          const SizedBox(height: 24),
        ],
        if (cats.isNotEmpty) ...[
          _Heading(text: l.browseCategories),
          _CategoryGrid(categories: cats),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(action!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ]),
      );
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PressScale(
      child: Material(
        color: scheme.surface,
        shape: StadiumBorder(side: BorderSide(color: dark ? NmColors.darkLine : NmColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, size: 17, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PopularList extends ConsumerWidget {
  const _PopularList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < products.length; i++)
          InkWell(
            onTap: () => openProduct(context, ref, products[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: i == products.length - 1 ? null : Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFF0F0EC))),
              ),
              child: Row(children: [
                SizedBox(width: 22, child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w800, fontSize: 15))),
                const SizedBox(width: 10),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 44, height: 44, child: NetImage(products[i].image, width: 120))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(products[i].nameIn(locale), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      products[i].off > 0 ? '${rupees(products[i].price)} · ${l.offTag(products[i].off)}' : rupees(products[i].price),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ]),
                ),
                const Icon(Icons.trending_up_rounded, color: NmColors.success, size: 20),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tints = dark ? CategoryTiles.darkTints : CategoryTiles.lightTints;
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 20) / 3;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < categories.length; i++)
          SizedBox(
            width: w,
            child: PressScale(
              child: Material(
                color: tints[i % tints.length],
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go('/shop?category=${categories[i].slug}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                    child: Column(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 56, height: 56, child: NetImage(categories[i].image, width: 160, icon: Icons.category_outlined))),
                      const SizedBox(height: 6),
                      Text(categories[i].nameIn(locale),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

// ───────────── While typing ─────────────

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.typed, required this.live, required this.onSeeAll, required this.onFill});

  final String typed;
  final String live;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final line = dark ? NmColors.darkLine : const Color(0xFFF0F0EC);
    final items = live.isEmpty ? const <Product>[] : ref.watch(suggestionsProvider(live)).value ?? const <Product>[];
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        InkWell(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.search_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l.seeAllResultsFor(typed), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 14.5))),
            ]),
          ),
        ),
        for (final p in items)
          InkWell(
            onTap: () => openProduct(context, ref, p),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 48, height: 48, child: NetImage(p.image, width: 120))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Highlighted(text: p.nameIn(locale), match: live),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(text: rupees(p.price), children: [
                      if (p.off > 0)
                        TextSpan(
                          text: '  ${rupees(p.mrp!)}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w400, decoration: TextDecoration.lineThrough),
                        ),
                    ]), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ]),
                ),
                IconButton(
                  tooltip: l.useThisName,
                  onPressed: () => onFill(p.nameIn(locale)),
                  icon: Transform.rotate(angle: -0.785, child: Icon(Icons.arrow_upward_rounded, color: scheme.onSurfaceVariant, size: 20)),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

/// The name with the typed letters in bold
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.match});

  final String text;
  final String match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = TextStyle(fontSize: 14.5, color: scheme.onSurface.withValues(alpha: 0.75));
    final at = match.isEmpty ? -1 : text.toLowerCase().indexOf(match.toLowerCase());
    return Text.rich(
      at < 0
          ? TextSpan(text: text)
          : TextSpan(children: [
              TextSpan(text: text.substring(0, at)),
              TextSpan(text: text.substring(at, at + match.length), style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
              TextSpan(text: text.substring(at + match.length)),
            ]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
}

// ───────────── Results ─────────────

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onChange, required this.onSearch});

  final SearchQuery query;
  final ValueChanged<SearchQuery> onChange;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final res = ref.watch(searchResultsProvider(query));
    final Widget content;
    if (res.hasError && !res.hasValue) {
      content = _Message(
        icon: Icons.wifi_off_rounded,
        title: l.loadError,
        body: l.loadErrorBody,
        button: l.tryAgain,
        onButton: () => ref.invalidate(searchResultsProvider(query)),
      );
    } else if (!res.hasValue) {
      content = const _ResultsSkeleton();
    } else {
      var items = res.value!;
      String? marathiWord;
      String? didYouMean;
      var similar = false;
      if (items.isEmpty) {
        // Nothing on the server: try the smarter match on the phone (needs the full product list)
        final all = ref.watch(allProductsProvider).value ?? const <Product>[];
        final smart = SmartSearch.smartMatch(query.text, all);
        items = smart.products.where(query.keeps).toList();
        marathiWord = smart.marathiWord;
        didYouMean = smart.didYouMean;
        similar = smart.similar;
      }
      if (items.isEmpty) {
        content = query.filtered
            ? _Message(
                icon: Icons.filter_alt_off_outlined,
                title: l.noFilterResults,
                body: l.noFilterResultsBody,
                button: l.clearFilters,
                onButton: () => onChange(SearchQuery(query.text, sort: query.sort)),
              )
            : _NoResults(query: query.text, didYouMean: didYouMean, onSearch: onSearch);
      } else {
        content = CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            if (marathiWord != null || similar)
              SliverToBoxAdapter(child: _Notice(text: marathiWord != null ? l.showingResultsFor(query.text, marathiWord) : l.showingSimilar)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: l.resultsCount(items.length), style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                    TextSpan(text: ' ${l.resultsFor(query.text)}'),
                  ]),
                  style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: (items.length + 1) ~/ 2,
              itemBuilder: (_, r) => ProductPair(left: items[r * 2], right: r * 2 + 1 < items.length ? items[r * 2 + 1] : null),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      }
    }
    return Column(children: [
      _FilterBar(query: query, onChange: onChange),
      Expanded(child: content),
    ]);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.query, required this.onChange});

  final SearchQuery query;
  final ValueChanged<SearchQuery> onChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sortLabel = _sortLabel(l, query.sort);
    Widget chip({required String label, required bool on, IconData? icon, required VoidCallback onTap}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            button: true,
            selected: on,
            child: Material(
              color: on ? scheme.primary.withValues(alpha: dark ? 0.25 : 0.12) : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: on ? scheme.primary : (dark ? NmColors.darkLine : NmColors.line)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null || on) ...[
                      Icon(on && icon == null ? Icons.check_rounded : icon, size: 17, color: on ? scheme.primary : scheme.onSurface),
                      const SizedBox(width: 5),
                    ],
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? scheme.primary : scheme.onSurface)),
                  ]),
                ),
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
      ),
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        children: [
          chip(
            label: sortLabel,
            on: query.sort != SearchSort.best,
            icon: Icons.swap_vert_rounded,
            onTap: () async {
              final s = await _pickSort(context, query.sort);
              if (s != null) onChange(query.copyWith(sort: s));
            },
          ),
          chip(label: l.filterInStock, on: query.inStock, onTap: () => onChange(query.copyWith(inStock: !query.inStock))),
          for (final max in const [199, 499, 999])
            chip(
              label: l.under(rupees(max)),
              on: query.maxPrice == max,
              onTap: () => onChange(query.copyWith(maxPrice: () => query.maxPrice == max ? null : max)),
            ),
        ],
      ),
    );
  }
}

String _sortLabel(AppLocalizations l, SearchSort s) => switch (s) {
      SearchSort.best => l.sortBest,
      SearchSort.priceLow => l.sortPriceLow,
      SearchSort.priceHigh => l.sortPriceHigh,
      SearchSort.discount => l.sortDiscount,
      SearchSort.newest => l.sortNewest,
    };

Future<SearchSort?> _pickSort(BuildContext context, SearchSort current) => showModalBottomSheet<SearchSort>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true, // as tall as the options need (scrolls on short screens)
      useSafeArea: true,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(l.sortBy, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
              ),
              RadioGroup<SearchSort>(
                groupValue: current,
                onChanged: (v) => Navigator.of(context).pop(v),
                child: Column(children: [
                  for (final s in SearchSort.values)
                    RadioListTile<SearchSort>(
                      value: s,
                      title: Text(_sortLabel(l, s), style: const TextStyle(fontWeight: FontWeight.w600)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                ]),
              ),
            ]),
          ),
        );
      },
    );

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2B2416) : const Color(0xFFFFF8E8),
        border: Border(bottom: BorderSide(color: dark ? const Color(0xFF4A3D1E) : const Color(0xFFF0DDB0))),
      ),
      child: Row(children: [
        Icon(Icons.translate_rounded, size: 19, color: dark ? NmColors.goldSoft : const Color(0xFF8A5A00)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface))),
      ]),
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults({required this.query, required this.didYouMean, required this.onSearch});

  final String query;
  final String? didYouMean;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final picks = (ref.watch(trendingProductsProvider).value ?? const <Product>[]).take(4).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 8),
          child: Column(children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.search_off_rounded, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(l.noResultsFor(query), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
            const SizedBox(height: 6),
            Text(l.noResultsBody, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45)),
            if (didYouMean != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => onSearch(didYouMean!),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  side: BorderSide(color: scheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text.rich(TextSpan(text: '${l.didYouMean} ', children: [
                  TextSpan(text: didYouMean, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
                  const TextSpan(text: '?'),
                ]), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ],
          ]),
        ),
      ),
      if (picks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text(l.youMightLike, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
          ),
        ),
        SliverList.builder(
          itemCount: (picks.length + 1) ~/ 2,
          itemBuilder: (_, r) => ProductPair(left: picks[r * 2], right: r * 2 + 1 < picks.length ? picks[r * 2 + 1] : null),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ]);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, required this.button, required this.onButton});

  final IconData icon;
  final String title;
  final String body;
  final String button;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(32, 48, 32, 32), children: [
      Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 38, color: scheme.primary),
        ),
      ),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
      const SizedBox(height: 6),
      Text(body, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      Center(child: FilledButton(onPressed: onButton, style: FilledButton.styleFrom(minimumSize: const Size(190, 50)), child: Text(button))),
    ]);
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: const [
          Skeleton(child: SkeletonBox(width: 140, height: 14)),
          SizedBox(height: 14),
          Row(children: [
            Expanded(child: ProductCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: ProductCardSkeleton()),
          ]),
          SizedBox(height: 16),
          Row(children: [
            Expanded(child: ProductCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: ProductCardSkeleton()),
          ]),
        ],
      );
}
