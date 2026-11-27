import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/cart/cart.dart';
import '../../core/catalog/catalog.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/recent_and_pincode.dart';
import '../../core/prefs.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/entrance.dart';
import '../../shared/net_image.dart';
import '../../shared/press_scale.dart';
import '../../shared/skeleton.dart';
import '../../shared/pincode_sheet.dart';
import 'home_sections.dart';

/// Home: a green greeting header with search, offer cards overlapping it, category tiles, Deal of the
/// Day with a flip-clock countdown, more deals, shop by budget, trending, recently viewed and every
/// product (mixed daily). Same data as the website's Home page, laid out like an app.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  final _scroll = ScrollController();
  bool _compact = false; // the green header has scrolled away: show the slim search bar
  int _shown = 20; // "Just for you" grows by 20 per tap
  Timer? _slowTimer;
  bool _slow = false; // the server is waking up (Render cold start): say so after 4 s

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final compact = _scroll.offset > 150;
      if (compact != _compact) setState(() => _compact = compact);
    });
    if (ref.read(liveUpdatesProvider)) {
      _slowTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && ref.read(allProductsProvider).isLoading) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _scroll.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(allProductsProvider);
    ref.invalidate(trendingProductsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(showBannerProvider);
    ref.invalidate(cartProvider);
    try {
      await Future.wait([ref.read(allProductsProvider.future), ref.read(trendingProductsProvider.future)]);
    } catch (_) {}
  }

  void _playIntro() {
    if (_intro.isAnimating || _intro.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final allQ = ref.watch(allProductsProvider);
    final trendQ = ref.watch(trendingProductsProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final showBanner = ref.watch(showBannerProvider).value ?? (ref.read(sharedPrefsProvider).getBool('nm_show_banner') ?? true);

    final loading = (allQ.isLoading && !allQ.hasValue) || (trendQ.isLoading && !trendQ.hasValue);
    final failed = allQ.hasError && !allQ.hasValue;
    if (!loading && _slow) _slow = false;

    final all = allQ.value ?? const <Product>[];
    final trending = trendQ.value ?? const <Product>[];
    final slides = loading || failed || !showBanner
        ? const <PromoSlide>[]
        : buildSlides(l: l, locale: locale, all: all, trending: trending, categories: cats);

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: _Hero(
          searchHints: [for (final p in [...trending, ...all]) if (p.name.length <= 22) p.nameIn(locale)].take(6).toList(),
          carousel: slides.isNotEmpty
              ? PromoCarousel(slides: slides)
              : (loading && showBanner)
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(homeGutter, 0, homeGutter, 24),
                      child: Skeleton(child: SkeletonBox(height: PromoCarousel.height, radius: 24)),
                    )
                  : null,
        ),
      ),
    ];

    if (failed) {
      slivers.add(SliverFillRemaining(hasScrollBody: false, child: _LoadError(onRetry: _refresh)));
    } else if (loading) {
      slivers.add(const SliverToBoxAdapter(child: HomeSkeleton()));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _playIntro() : null);
      final deals = byDiscount(all.where((p) => !p.soldOut && p.off >= 10)).take(13).toList();
      final mixed = mixProducts(all);
      var step = 0;
      Widget enter(Widget child) => Entrance(controller: _intro, delayMs: 90 * step++, distance: 24, child: child);
      SliverToBoxAdapter box(Widget child, {double top = 0}) =>
          SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: top), child: enter(child)));

      if (cats.isNotEmpty) {
        slivers.add(box(
          Column(children: [
            SectionTitle(title: l.catTitle, alt: l.catAlt, action: l.seeAll, onAction: () => context.go('/shop')),
            CategoryTiles(categories: cats),
          ]),
          top: slides.isEmpty ? 22 : 16,
        ));
      }
      if (deals.isNotEmpty) slivers.add(box(DealOfTheDay(product: deals.first), top: 26));
      if (deals.length > 1) {
        slivers.add(box(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle(title: l.moreDealsTitle, alt: l.moreDealsAlt, action: l.seeAll, onAction: () => context.go('/shop?sort_by=discount')),
            ProductRail(products: deals.skip(1).toList()),
          ]),
          top: 26,
        ));
      }
      slivers.add(box(Column(children: [SectionTitle(title: l.budgetTitle, alt: l.budgetAlt), BudgetCards(all: all)]), top: 26));
      if (trending.isNotEmpty) {
        slivers.add(box(
          Column(children: [
            SectionTitle(title: '🔥 ${l.trendingNow}', alt: l.trendingAlt, action: l.viewAll, onAction: () => context.go('/shop?trending=true')),
            ProductGrid(products: trending.take(6).toList()),
          ]),
          top: 26,
        ));
      }
      slivers.add(const SliverToBoxAdapter(child: _RecentlyViewed()));
      if (mixed.isNotEmpty) {
        final shown = mixed.take(_shown).toList();
        slivers.add(box(SectionTitle(title: l.justForYou, alt: l.justForYouAlt), top: 26));
        slivers.add(SliverList.builder(
          itemCount: (shown.length + 1) ~/ 2,
          itemBuilder: (_, r) => ProductPair(left: shown[r * 2], right: r * 2 + 1 < shown.length ? shown[r * 2 + 1] : null),
        ));
        if (_shown < mixed.length) {
          slivers.add(SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(homeGutter, 6, homeGutter, 0),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _shown += 20),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(l.showMore(mixed.length - _shown)),
              ),
            ),
          ));
        }
      }
      slivers.add(const SliverToBoxAdapter(child: HomeFooter()));
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _compact && !dark ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              edgeOffset: MediaQuery.paddingOf(context).top,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                ignoring: !_compact,
                child: AnimatedSlide(
                  offset: _compact ? Offset.zero : const Offset(0, -1),
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: const _CompactBar(),
                ),
              ),
            ),
            if (_slow) const _SlowHint(),
          ],
        ),
      ),
    );
  }
}

/// Every product, categories taken in turn, in a shuffled order that stays the same all day
/// (port of the website's mixProducts)
List<Product> mixProducts(List<Product> all, {DateTime? today}) {
  final d = today ?? DateTime.now();
  var seed = d.year * 10000 + d.month * 100 + d.day;
  double rand() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280;
  }

  final groups = <int, List<Product>>{};
  for (final p in all) {
    (groups[p.categoryId ?? 0] ??= []).add(p);
  }
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = (rand() * (i + 1)).floor();
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }

  final lists = groups.values.toList();
  for (final g in lists) {
    shuffle(g);
  }
  shuffle(lists);
  final out = <Product>[];
  for (var i = 0; out.length < all.length; i++) {
    for (final g in lists) {
      if (i < g.length) out.add(g[i]);
    }
  }
  return out;
}

// ───────────── Green header: greeting, deliver-to, bag, search; offer cards overlap its bottom ─────────────

class _Hero extends ConsumerWidget {
  const _Hero({required this.searchHints, required this.carousel});

  final List<String> searchHints;
  final Widget? carousel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = ref.watch(authProvider.select((a) => a.value?.firstName));
    final pin = ref.watch(pincodeProvider);
    // The green reaches a little under half-way into the offer cards
    final greenBottom = carousel == null ? 0.0 : PromoCarousel.heightFor(context) * 0.58 + 24;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: greenBottom,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark ? const [NmColors.brandDark, Color(0xFF14341A)] : const [NmColors.brand, NmColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Stack(children: [
                Positioned(right: -60, top: -50, child: _Blob(size: 220, alpha: 0.07)),
                Positioned(left: -40, bottom: -70, child: _Blob(size: 160, alpha: 0.05)),
              ]),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 10),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(homeGutter, 0, 10, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              name == null || name.isEmpty ? l.homeGreetingGuest : l.homeGreeting(name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          _DeliverTo(pin: pin),
                        ],
                      ),
                    ),
                    const BagButton(onGreen: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: homeGutter),
              child: _SearchPill(hints: searchHints, raised: true),
            ),
            SizedBox(height: carousel == null ? 26 : 18),
            ?carousel,
          ],
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}

/// Slim white bar with search and the bag, slid in once the green header has scrolled away
class _CompactBar extends ConsumerWidget {
  const _CompactBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.fromLTRB(homeGutter, MediaQuery.paddingOf(context).top + 6, 6, 8),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: const Row(children: [
            Expanded(child: _SearchPill(hints: [], raised: false)),
            SizedBox(width: 4),
            BagButton(onGreen: false),
          ]),
        ),
      ),
    );
  }
}

/// Bag icon with a red count that pops each time it changes
class BagButton extends ConsumerWidget {
  const BagButton({super.key, required this.onGreen});

  final bool onGreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final count = ref.watch(cartProvider.select((c) => c.value?.count ?? 0));
    final ink = onGreen ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return IconButton(
      tooltip: count > 0 ? '${l.homeBag}, $count' : l.homeBag,
      onPressed: () => context.push('/bag'),
      style: IconButton.styleFrom(
        backgroundColor: onGreen ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        fixedSize: const Size(46, 46),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.shopping_bag_outlined, color: ink, size: 24),
          if (count > 0)
            Positioned(
              right: -9,
              top: -7,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(count),
                tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 1.5, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19),
                  height: 19,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: NmColors.deal,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: onGreen ? NmColors.brand : Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Search bar (opens Search). On the green header the hint cycles through real product names.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.hints, required this.raised});

  final List<String> hints;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = raised ? scheme.surface : (dark ? const Color(0xFF22252B) : NmColors.muted);
    return PressScale(
      scale: 0.98,
      child: Semantics(
        button: true,
        label: l.homeSearchHint,
        excludeSemantics: true,
        child: Container(
          height: raised ? 52 : 46,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            boxShadow: raised ? const [BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 8))] : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/search'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: scheme.primary, size: 23),
                    const SizedBox(width: 10),
                    Expanded(
                      child: hints.isEmpty
                          ? Text(l.homeSearchHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500))
                          : _RotatingHint(hints: hints),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search "steel bottle" → Search "torch" → … every 3 s, rolling up
class _RotatingHint extends ConsumerStatefulWidget {
  const _RotatingHint({required this.hints});

  final List<String> hints;

  @override
  ConsumerState<_RotatingHint> createState() => _RotatingHintState();
}

class _RotatingHintState extends ConsumerState<_RotatingHint> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (ref.read(liveUpdatesProvider)) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted && widget.hints.isNotEmpty) setState(() => _i = (_i + 1) % widget.hints.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final word = widget.hints[_i % widget.hints.length];
    final still = MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        Text('${l.homeSearchFor} ', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
        Expanded(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: still ? Duration.zero : const Duration(milliseconds: 350),
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.8), end: Offset.zero).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
              child: Text('"$word"',
                  key: ValueKey(word),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliverTo extends StatelessWidget {
  const _DeliverTo({required this.pin});

  final String? pin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => showPincodeSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 3),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '${l.homeDeliverTo} ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                    children: [TextSpan(text: pin ?? l.homeAddPincode, style: const TextStyle(color: NmColors.goldSoft, fontWeight: FontWeight.w800))],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── Recently viewed, errors, slow server ─────────────

class _RecentlyViewed extends ConsumerWidget {
  const _RecentlyViewed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(recentIdsProvider);
    if (ids.isEmpty) return const SizedBox.shrink();
    final items = ref.watch(productsByIdsProvider(ids.join(','))).value ?? const <Product>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(children: [
        SectionTitle(eyebrow: l.recentEyebrow, title: l.recentTitle),
        ProductRail(products: items, cardWidth: 142),
      ]),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.wifi_off_rounded, size: 38, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(l.loadError, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: 6),
          Text(l.loadErrorBody, textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.tryAgain),
          ),
        ],
      ),
    );
  }
}

class _SlowHint extends StatelessWidget {
  const _SlowHint();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
          child: Container(
            constraints: BoxConstraints(maxWidth: math.min(MediaQuery.sizeOf(context).width - 32, 420)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(color: NmColors.ink, borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: NmColors.brandOnDark)),
              const SizedBox(width: 10),
              Flexible(child: Text(l.loadingSlow, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      ),
    );
  }
}
