import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cart/cart.dart';
import '../../core/catalog/catalog.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/shop.dart';
import '../../core/format.dart';
import '../../core/prefs.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';
import '../home/home_sections.dart' show ProductPair, homeGutter;
import 'shop_filters_sheet.dart';

/// Shop tab: category pills, filters, sort, grid or list, more products as you scroll.
/// Opens already filtered from links like /shop?category=bathroom or /shop?max_price=999.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initial = const ShopFilters()});

  final ShopFilters initial;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late ShopFilters _f = widget.initial;
  final _scroll = ScrollController();
  int _pages = 1; // pages of results loaded so far
  bool _showTop = false;

  static const _viewKey = 'nm_shop_view';
  late bool _list = ref.read(sharedPrefsProvider).getString(_viewKey) == 'list';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final top = _scroll.offset > 900;
    if (top != _showTop) setState(() => _showTop = top);
    // Next page when 600 px from the bottom
    if (_scroll.position.extentAfter < 600) {
      final last = ref.read(shopPageProvider((_f, _pages))).value;
      if (last != null && _pages < last.pages) setState(() => _pages++);
    }
  }

  void _set(ShopFilters f) {
    if (f == _f) return;
    setState(() {
      _f = f;
      _pages = 1;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _setView(bool list) {
    setState(() => _list = list);
    ref.read(sharedPrefsProvider).setString(_viewKey, list ? 'list' : 'grid');
  }

  Future<void> _refresh() async {
    for (var p = 1; p <= _pages; p++) {
      ref.invalidate(shopPageProvider((_f, p)));
    }
    ref.invalidate(categoriesProvider);
    setState(() => _pages = 1);
    try {
      await ref.read(shopPageProvider((_f, 1)).future);
    } catch (_) {}
  }

  Future<void> _openFilters() async {
    final f = await showShopFilters(context, _f);
    if (f != null) _set(f);
  }

  Future<void> _openSort() async {
    final s = await showShopSort(context, _f.sort);
    if (s != null) _set(_f.copyWith(sort: s));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final cat = cats.where((c) => c.slug == _f.category).firstOrNull;

    // Everything loaded so far, page by page
    final first = ref.watch(shopPageProvider((_f, 1)));
    final items = <Product>[];
    var loadingMore = false;
    for (var p = 1; p <= _pages; p++) {
      final page = ref.watch(shopPageProvider((_f, p)));
      if (page.value != null) {
        items.addAll(page.value!.items);
      } else {
        loadingMore = p > 1;
        break;
      }
    }
    final total = first.value?.total;

    final title = cat != null
        ? cat.nameIn(locale)
        : _f.trending
        ? '🔥 ${l.catTrendingChip}'
        : l.tabShop;
    final alt = cat != null
        ? cat.altNameIn(locale)
        : _f.trending
        ? l.trendingAlt
        : l.shopAlt;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: _ActiveFilters(f: _f, onChanged: _set),
      ),
    ];
    if (first.hasError && !first.hasValue) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.wifi_off_rounded,
            title: l.loadError,
            body: l.loadErrorBody,
            button: l.tryAgain,
            onButton: () => ref.invalidate(shopPageProvider((_f, 1))),
          ),
        ),
      );
    } else if (!first.hasValue) {
      slivers.add(SliverToBoxAdapter(child: _ListSkeleton(list: _list)));
    } else if (items.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _f.count > 0
              ? _Message(
                  icon: Icons.filter_alt_off_outlined,
                  title: l.noFilterResults,
                  body: l.noFilterResultsBody,
                  button: l.clearFilters,
                  onButton: () => _set(_f.cleared()),
                )
              : _Message(
                  icon: Icons.inventory_2_outlined,
                  title: l.shopEmpty,
                  body: l.shopEmptyBody,
                  button: l.seeAllProducts,
                  onButton: () => _set(const ShopFilters()),
                ),
        ),
      );
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(homeGutter, 10, homeGutter - 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.productsCount(total ?? items.length),
                          style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        TextSpan(text: ' · ${_sortLabel(l, _f.sort).toLowerCase()}'),
                      ],
                    ),
                    style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                ViewSwitch(list: _list, onChanged: _setView),
              ],
            ),
          ),
        ),
      );
      if (_list) {
        slivers.add(
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ProductListTile(product: items[i]),
          ),
        );
      } else {
        slivers.add(
          SliverList.builder(
            itemCount: (items.length + 1) ~/ 2,
            itemBuilder: (_, r) => ProductPair(left: items[r * 2], right: r * 2 + 1 < items.length ? items[r * 2 + 1] : null),
          ),
        );
      }
      if (loadingMore) slivers.add(SliverToBoxAdapter(child: _ListSkeleton(list: _list, rows: 1)));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            _Header(
              title: title,
              subtitle: [?alt, if (total != null) l.productsCount(total)].join(' · '),
              categories: cats,
              filters: _f,
              onChanged: _set,
              onFilters: _openFilters,
              onSort: _openSort,
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(controller: _scroll, physics: const AlwaysScrollableScrollPhysics(), slivers: slivers),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: AnimatedScale(
          scale: _showTop ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
          child: FloatingActionButton.small(
            tooltip: l.backToTop,
            heroTag: 'shop-top',
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => MediaQuery.disableAnimationsOf(context)
                ? _scroll.jumpTo(0)
                : _scroll.animateTo(0, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic),
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
    );
  }
}

String _sortLabel(AppLocalizations l, ShopSort s) => switch (s) {
  ShopSort.newest => l.sortNewest,
  ShopSort.priceLow => l.sortPriceLow,
  ShopSort.priceHigh => l.sortPriceHigh,
  ShopSort.discount => l.sortDiscount,
  ShopSort.popular => l.sortPopular,
};

// ───────────── Header: title, category pills, toolbar ─────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.filters,
    required this.onChanged,
    required this.onFilters,
    required this.onSort,
  });

  final String title;
  final String subtitle;
  final List<Category> categories;
  final ShopFilters filters;
  final ValueChanged<ShopFilters> onChanged;
  final VoidCallback onFilters;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final f = filters;
    final count = ref.watch(cartProvider.select((c) => c.value?.count ?? 0));
    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(homeGutter, 0, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.homeSearchHint,
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: count > 0 ? '${l.homeBag}, $count' : l.homeBag,
                    onPressed: () => context.push('/bag'),
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 99 ? '99+' : '$count'),
                      backgroundColor: NmColors.deal,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                ],
              ),
            ),
            _CategoryPills(categories: categories, filters: f, onChanged: onChanged),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(homeGutter, 4, 8, 10),
                children: [
                  _ToolChip(icon: Icons.tune_rounded, label: l.filters, on: f.count > 0, badge: f.count, onTap: onFilters),
                  _ToolChip(
                    icon: Icons.swap_vert_rounded,
                    label: _sortLabel(l, f.sort),
                    on: f.sort != ShopSort.newest,
                    onTap: onSort,
                  ),
                  _ToolChip(
                    label: l.filterInStock,
                    on: f.inStock,
                    onTap: () => onChanged(f.copyWith(inStock: !f.inStock)),
                  ),
                  _ToolChip(
                    label: l.under(rupees(499)),
                    on: f.maxPrice == 499 && f.minPrice == null,
                    onTap: () => onChanged(
                      f.maxPrice == 499 && f.minPrice == null
                          ? f.copyWith(maxPrice: () => null)
                          : f.copyWith(maxPrice: () => 499, minPrice: () => null),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPills extends StatefulWidget {
  const _CategoryPills({required this.categories, required this.filters, required this.onChanged});

  final List<Category> categories;
  final ShopFilters filters;
  final ValueChanged<ShopFilters> onChanged;

  @override
  State<_CategoryPills> createState() => _CategoryPillsState();
}

class _CategoryPillsState extends State<_CategoryPills> {
  final _selected = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_CategoryPills old) {
    super.didUpdateWidget(old);
    if (old.filters.category != widget.filters.category ||
        old.filters.trending != widget.filters.trending ||
        old.categories.length != widget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: true));
    }
  }

  /// Keeps the chosen pill on screen (links can open a category far along the row)
  void _reveal({required bool animate}) {
    final c = _selected.currentContext;
    if (c == null || !mounted) return;
    Scrollable.ensureVisible(
      c,
      alignment: 0.3,
      duration: animate && !MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 300) : Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final f = widget.filters;
    final all = f.category == null && !f.trending;
    // A new category has its own brands and prices, so those filters reset
    ShopFilters pick({String? category, bool trending = false}) =>
        ShopFilters(category: category, trending: trending, sort: f.sort, inStock: f.inStock);
    final pills = [
      (key: 'all', label: l.allProducts, icon: Icons.apps_rounded, image: null, on: all, to: pick()),
      (
        key: 'trending',
        label: l.catTrendingChip,
        icon: Icons.local_fire_department_rounded,
        image: null,
        on: f.trending,
        to: pick(trending: true),
      ),
      for (final c in widget.categories)
        (key: c.slug, label: c.nameIn(locale), icon: null, image: c.image, on: f.category == c.slug, to: pick(category: c.slug)),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(homeGutter, 8, homeGutter, 6),
        children: [
          for (final p in pills)
            Padding(
              key: p.on ? _selected : ValueKey(p.key),
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(label: p.label, icon: p.icon, image: p.image, on: p.on, onTap: () => widget.onChanged(p.to)),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.image, required this.on, required this.onTap});

  final String label;
  final IconData? icon;
  final String? image;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = on ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? scheme.primary : scheme.surface,
        shape: StadiumBorder(side: BorderSide(color: on ? scheme.primary : (dark ? NmColors.darkLine : NmColors.line))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? Colors.white.withValues(alpha: 0.2) : (dark ? const Color(0xFF22252B) : NmColors.muted),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: icon != null
                      ? Icon(
                          icon,
                          size: 17,
                          color: on
                              ? fg
                              : (icon == Icons.local_fire_department_rounded ? NmColors.deal : scheme.onSurfaceVariant),
                        )
                      : NetImage(image, width: 80, icon: Icons.category_outlined),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({this.icon, required this.label, required this.on, required this.onTap, this.badge = 0});

  final IconData? icon;
  final String label;
  final bool on;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = on ? (dark ? NmColors.brandOnDark : NmColors.brandDark) : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
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
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 5)],
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
                  ),
                  if (badge > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(9)),
                      child: Text(
                        '$badge',
                        style: TextStyle(color: scheme.onPrimary, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────── Active filters ─────────────

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.f, required this.onChanged});

  final ShopFilters f;
  final ValueChanged<ShopFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    if (f.count == 0) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final chips = <(String, ShopFilters)>[
      if (f.inStock) (l.filterInStock, f.copyWith(inStock: false)),
      if (f.hasPrice) (priceRangeLabel(l, f.minPrice, f.maxPrice), f.copyWith(minPrice: () => null, maxPrice: () => null)),
      for (final b in f.brands) (b, f.copyWith(brands: {...f.brands}..remove(b))),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(homeGutter, 12, homeGutter, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (label, next) in chips)
            Semantics(
              button: true,
              label: l.removeFilter(label),
              excludeSemantics: true,
              child: Material(
                color: dark ? Colors.white : NmColors.ink,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onChanged(next),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(color: dark ? NmColors.ink : Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.close_rounded, size: 15, color: dark ? NmColors.ink : Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: () => onChanged(f.cleared()),
            style: TextButton.styleFrom(minimumSize: const Size(0, 30), padding: const EdgeInsets.symmetric(horizontal: 6)),
            child: Text(
              l.clearAll,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Under ₹499", "₹1,000+", "₹100 – ₹1,500"
String priceRangeLabel(AppLocalizations l, int? min, int? max) {
  if (min == null && max != null) return l.under(rupees(max));
  if (max == null && min != null) return '${rupees(min)}+';
  return '${rupees(min ?? 0)} – ${rupees(max ?? 0)}';
}

// ───────────── Grid / list ─────────────

/// Grid | list switch (Shop and Wishlist)
class ViewSwitch extends StatelessWidget {
  const ViewSwitch({super.key, required this.list, required this.onChanged});

  final bool list;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget btn(IconData icon, String tip, bool on, bool value) => Tooltip(
      message: tip,
      child: Semantics(
        button: true,
        selected: on,
        label: tip,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onChanged(value),
          child: Container(
            width: 38,
            height: 34,
            color: on ? scheme.primary.withValues(alpha: dark ? 0.22 : 0.12) : Colors.transparent,
            child: Icon(icon, size: 19, color: on ? scheme.primary : scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: dark ? NmColors.darkLine : NmColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.grid_view_rounded, l.viewGrid, !list, false),
          btn(Icons.view_agenda_outlined, l.viewList, list, true),
        ],
      ),
    );
  }
}

/// List view row: big photo, name in both languages, price, savings, heart and ADD
class ProductListTile extends ConsumerWidget {
  const ProductListTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final alt = p.altNameIn(locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(homeGutter, 0, homeGutter, 10),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openProduct(context, ref, p),
          child: Ink(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 116,
                    height: 116,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NetImage(p.image, width: 300),
                          if (p.off >= 10) Positioned(left: 6, top: 6, child: OffTag(off: p.off)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          p.nameIn(locale),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.25),
                        ),
                        if (alt != null)
                          Text(
                            alt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
                          ),
                        const SizedBox(height: 5),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 5,
                          children: [
                            Text(rupees(p.price), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
                            if (p.off > 0)
                              Text(
                                rupees(p.mrp!),
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        if (p.off > 0)
                          Text(
                            l.youSave(rupees(p.mrp! - p.price)),
                            style: const TextStyle(color: NmColors.success, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            HeartButton(product: p),
                            const Spacer(),
                            if (p.soldOut)
                              Text(
                                l.outOfStock,
                                style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12),
                              )
                            else
                              AddButton(product: p),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────── Loading and messages ─────────────

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.list, this.rows = 2});

  final bool list;
  final int rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(homeGutter, 14, homeGutter, 0),
    child: Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: list
                ? const Skeleton(
                    child: Row(
                      children: [
                        SkeletonBox(width: 116, height: 116, radius: 16),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 14, width: double.infinity),
                              SizedBox(height: 8),
                              SkeletonBox(height: 12, width: 110),
                              SizedBox(height: 14),
                              SkeletonBox(height: 16, width: 70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const Row(
                    children: [
                      Expanded(child: ProductCardSkeleton()),
                      SizedBox(width: 12),
                      Expanded(child: ProductCardSkeleton()),
                    ],
                  ),
          ),
      ],
    ),
  );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onButton,
            style: FilledButton.styleFrom(minimumSize: const Size(190, 50)),
            child: Text(button),
          ),
        ],
      ),
    );
  }
}
