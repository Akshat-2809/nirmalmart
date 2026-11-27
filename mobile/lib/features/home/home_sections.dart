import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog/models.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/press_scale.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';

/// Gap between the screen edge and content, and between cards
const homeGutter = 16.0;
const _gap = 12.0;

int maxOff(Iterable<Product> items) => items.fold(0, (m, p) => math.max(m, p.off));
List<Product> byDiscount(Iterable<Product> items) => [...items]..sort((a, b) => b.off.compareTo(a.off));

// ───────────── Section title ─────────────

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.alt, this.eyebrow, this.action, this.onAction, this.trailing});

  final String title;
  final String? alt;
  final String? eyebrow;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(homeGutter, 0, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(eyebrow!.toUpperCase(),
                      style: t.bodySmall!.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: scheme.primary)),
                Text(title, style: t.titleLarge!.copyWith(fontSize: 20, height: 1.2)),
                if (alt != null) Text(alt!, style: t.bodySmall!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                if (trailing != null) Padding(padding: const EdgeInsets.only(top: 8), child: trailing),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action!, style: t.labelLarge!.copyWith(color: scheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, size: 17, color: scheme.primary),
              ]),
            ),
        ],
      ),
    );
  }
}

// ───────────── Offer carousel (built from real products, like the website) ─────────────

enum SlideTheme { green, maroon, gold }

class PromoSlide {
  const PromoSlide({
    required this.key,
    required this.theme,
    required this.badge,
    required this.title,
    required this.alt,
    required this.line,
    required this.href,
    required this.images,
  });

  final String key;
  final SlideTheme theme;
  final String badge;
  final String title;
  final String? alt;
  final String line;
  final String href;
  final List<String?> images;
}

List<PromoSlide> buildSlides({
  required AppLocalizations l,
  required Locale locale,
  required List<Product> all,
  required List<Product> trending,
  required List<Category> categories,
}) {
  final slides = <PromoSlide>[];
  List<String?> pics(Iterable<Product> items) => byDiscount(items).take(2).map((p) => p.image).toList();
  final under999 = all.where((p) => p.price < 1000).toList();
  if (under999.isNotEmpty) {
    slides.add(PromoSlide(
      key: 'u999',
      theme: SlideTheme.maroon,
      badge: l.promoBudgetBadge,
      title: l.promoBudgetTitle,
      alt: l.promoBudgetAlt,
      line: l.promoBudgetLine(under999.length),
      href: '/shop?max_price=999',
      images: pics(under999),
    ));
  }
  if (trending.isNotEmpty) {
    slides.add(PromoSlide(
      key: 'trending',
      theme: SlideTheme.green,
      badge: l.promoTrendingBadge,
      title: l.promoTrendingTitle,
      alt: l.promoTrendingAlt,
      line: l.promoUpTo(maxOff(trending)),
      href: '/shop?trending=true',
      images: pics(trending),
    ));
  }
  final top = [...categories]..sort((a, b) => b.productCount.compareTo(a.productCount));
  for (final c in top.take(2)) {
    final items = all.where((p) => p.categoryId == c.id).toList();
    if (items.isEmpty) continue;
    slides.add(PromoSlide(
      key: 'c${c.id}',
      theme: SlideTheme.gold,
      badge: l.promoCategoryBadge,
      title: c.nameIn(locale),
      alt: c.altNameIn(locale),
      line: l.promoFrom(rupees(items.map((p) => p.price).reduce(math.min))),
      href: '/shop?category=${c.slug}',
      images: pics(items),
    ));
  }
  return slides;
}

class PromoCarousel extends ConsumerStatefulWidget {
  const PromoCarousel({super.key, required this.slides});

  final List<PromoSlide> slides;

  static const height = 184.0;

  /// Taller with bigger phone text, so nothing is cut off
  static double heightFor(BuildContext context) => MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2).scale(150) + 44; // room for a two-line title

  @override
  ConsumerState<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<PromoCarousel> {
  // Each card is a little narrower than the screen so the next one peeks in
  final _pages = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _index = 0;
  bool _firstRound = true;
  bool _held = false;

  int get _n => widget.slides.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(PromoCarousel old) {
    super.didUpdateWidget(old);
    if (_index >= _n) _index = 0;
    _schedule();
  }

  /// Auto-advance like the website: the first slide stays 10 s so the screen settles, then every 5 s.
  /// Paused while a finger is on it.
  void _schedule() {
    _timer?.cancel();
    if (_n < 2 || _held || !ref.read(liveUpdatesProvider)) return;
    _timer = Timer(Duration(seconds: _firstRound ? 10 : 5), () {
      if (!mounted || !_pages.hasClients) return;
      _firstRound = false;
      final next = (_index + 1) % _n;
      if (MediaQuery.disableAnimationsOf(context)) {
        _pages.jumpToPage(next);
      } else {
        _pages.animateToPage(next, duration: NmMotion.carouselSlide, curve: const Cubic(0.6, 0, 0.2, 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.offersLabel,
      container: true,
      child: Listener(
        onPointerDown: (_) {
          _held = true;
          _timer?.cancel();
        },
        onPointerUp: (_) {
          _held = false;
          _schedule();
        },
        onPointerCancel: (_) {
          _held = false;
          _schedule();
        },
        child: Column(
          children: [
            SizedBox(
              height: PromoCarousel.heightFor(context) + 18, // + room for the card shadow
              child: PageView.builder(
                controller: _pages,
                padEnds: false,
                itemCount: _n,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _schedule();
                },
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(left: homeGutter, right: i == _n - 1 ? homeGutter : 0, bottom: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x40173D1D), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: _SlideView(slide: widget.slides[i])),
                    ),
                  ),
                ),
              ),
            ),
            if (_n > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _n; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final PromoSlide slide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = slide;
    final (colors, ink, accent) = switch (s.theme) {
      SlideTheme.green => ([const Color(0xFF245A2B), const Color(0xFF0E2612)], Colors.white, NmColors.goldSoft),
      SlideTheme.maroon => ([NmColors.maroon, const Color(0xFF8F1D2A)], Colors.white, NmColors.goldSoft),
      SlideTheme.gold => ([const Color(0xFFF5E6BF), NmColors.gold], const Color(0xFF2B2110), NmColors.maroon),
    };
    return Semantics(
      button: true,
      label: '${s.title}. ${s.line}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.go(s.href),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(
            children: [
              // soft rings for depth
              Positioned(right: -40, top: -50, child: _Ring(size: 200, color: Colors.white.withValues(alpha: 0.08))),
              Positioned(right: 70, bottom: -70, child: _Ring(size: 140, color: Colors.white.withValues(alpha: 0.06))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: ink.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.local_fire_department_rounded, size: 12, color: ink),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(s.badge.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(s.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: ink, fontSize: 23, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                          if (s.alt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(s.alt!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: ink.withValues(alpha: 0.88), fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 3),
                          Text(s.line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: accent, fontSize: 13.5, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
                            decoration: BoxDecoration(
                              color: s.theme == SlideTheme.gold ? NmColors.ink : Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: Text(l.shopNow,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: s.theme == SlideTheme.gold ? Colors.white : NmColors.ink,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded,
                                  size: 17, color: s.theme == SlideTheme.gold ? Colors.white : NmColors.ink),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    // photos take about a third of the banner (smaller on narrow phones)
                    Builder(builder: (context) {
                      final w = (MediaQuery.sizeOf(context).width * 0.34).clamp(92.0, 128.0);
                      return SizedBox(width: w, child: _SlidePhotos(images: s.images, scale: w / 128));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// One or two product photos in white tiles, tilted, gently floating
class _SlidePhotos extends StatefulWidget {
  const _SlidePhotos({required this.images, this.scale = 1});

  final List<String?> images;
  final double scale;

  @override
  State<_SlidePhotos> createState() => _SlidePhotosState();
}

class _SlidePhotosState extends State<_SlidePhotos> with SingleTickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Widget _tile(String? url, double size, double angle) => Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: NetImage(url, width: 220)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final y = math.sin(_float.value * 2 * math.pi) * 5;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (imgs.length > 1) Positioned(left: 0, bottom: 4 - y, child: _tile(imgs[1], 66 * widget.scale, -0.14)),
            Positioned(right: 2, top: 10 + y, child: _tile(imgs.isEmpty ? null : imgs.first, 104 * widget.scale, 0.1)),
          ],
        );
      },
    );
  }
}

// ───────────── Category tiles ─────────────

/// Pastel square tiles in two rows that scroll sideways
class CategoryTiles extends StatelessWidget {
  const CategoryTiles({super.key, required this.categories});

  final List<Category> categories;

  static const lightTints = [
    Color(0xFFE9F3EB), Color(0xFFFDF1DC), Color(0xFFF6E3E5), Color(0xFFE6EEF8), Color(0xFFEFE9F7),
    Color(0xFFFFF4D6), Color(0xFFE4F4F1), Color(0xFFF9E8DD), Color(0xFFEDEDE7),
  ];
  static const darkTints = [
    Color(0xFF1F3323), Color(0xFF3A2F17), Color(0xFF3A1A1E), Color(0xFF1C2838), Color(0xFF2A2238),
    Color(0xFF3A3315), Color(0xFF173330), Color(0xFF38261C), Color(0xFF2A2B27),
  ];

  /// One tile: the square plus two lines of name at the phone's text size
  static double tileHeight(BuildContext context) => 86 + MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6).scale(30);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rows = categories.length > 4 ? 2 : 1;
    final h = tileHeight(context);
    return SizedBox(
      height: h * rows + (rows - 1) * 12,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: homeGutter),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: rows,
          mainAxisSpacing: 10,
          crossAxisSpacing: 12,
          mainAxisExtent: 80,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          return _CategoryTile(
            name: c.nameIn(locale),
            image: c.image,
            tint: (dark ? darkTints : lightTints)[i % lightTints.length],
            onTap: () => context.go('/shop?category=${c.slug}'),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.image, required this.tint, required this.onTap});

  final String name;
  final String? image;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: name,
        excludeSemantics: true,
        child: PressScale(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(22)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(14), child: NetImage(image, width: 160, icon: Icons.category_outlined)),
                ),
                const SizedBox(height: 6),
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );
}

// ───────────── Product rail and grid ─────────────

/// Horizontal row of product cards that all share the tallest one's height
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products, this.cardWidth = 150});

  final List<Product> products;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: homeGutter),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < products.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                SizedBox(width: cardWidth, child: ProductCard(product: products[i])),
              ],
            ],
          ),
        ),
      );
}

/// Two product cards side by side, the same height
class ProductPair extends StatelessWidget {
  const ProductPair({super.key, required this.left, this.right});

  final Product left;
  final Product? right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(homeGutter, 0, homeGutter, _gap),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: ProductCard(product: left)),
              const SizedBox(width: _gap),
              Expanded(child: right == null ? const SizedBox.shrink() : ProductCard(product: right!)),
            ],
          ),
        ),
      );
}

/// Products as rows of two (a plain Column; use the sliver version for long lists)
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < products.length; i += 2)
            ProductPair(left: products[i], right: i + 1 < products.length ? products[i + 1] : null),
        ],
      );
}

// ───────────── Countdown to midnight ─────────────

/// Time left until midnight, like the website's Today's Deals timer: (hours, minutes, seconds)
(int, int, int) untilMidnight(DateTime now) {
  final s = math.max(0, DateTime(now.year, now.month, now.day + 1).difference(now).inSeconds);
  return (s ~/ 3600, s % 3600 ~/ 60, s % 60);
}

/// "Ends in 05 : 12 : 33" with dark flip-clock tiles, ticking every second
class FlipCountdown extends ConsumerStatefulWidget {
  const FlipCountdown({super.key, this.now});

  /// Fixed time for tests and previews
  final DateTime Function()? now;

  @override
  ConsumerState<FlipCountdown> createState() => _FlipCountdownState();
}

class _FlipCountdownState extends ConsumerState<FlipCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (ref.read(liveUpdatesProvider)) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (h, m, sec) = untilMidnight((widget.now ?? DateTime.now)());
    String two(int v) => v.toString().padLeft(2, '0');
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    Widget tile(String v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: dark ? Colors.white : NmColors.ink, borderRadius: BorderRadius.circular(7)),
          child: Stack(alignment: Alignment.center, children: [
            Text(v,
                style: TextStyle(
                    color: dark ? NmColors.ink : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            // the fold line of a flip clock
            Positioned(left: 0, right: 0, child: Container(height: 1, color: (dark ? NmColors.ink : Colors.white).withValues(alpha: 0.18))),
          ]),
        );
    Widget colon() => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text(':', style: TextStyle(fontWeight: FontWeight.w800, color: ink)));
    return Semantics(
      label: '${l.dealsEndsIn} ${two(h)}:${two(m)}:${two(sec)}',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(l.dealsEndsIn, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
          tile(two(h)),
          colon(),
          tile(two(m)),
          colon(),
          tile(two(sec)),
        ],
      ),
    );
  }
}

// ───────────── Deal of the day ─────────────

/// The biggest in-stock discount, large, with the countdown and how many are left
class DealOfTheDay extends ConsumerWidget {
  const DealOfTheDay({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = product;
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final few = p.stock <= 20;
    // fuller bar = more urgent
    final urgency = few ? ((20 - p.stock) / 20).clamp(0.12, 0.95) : 0.55;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: PressScale(
        scale: 0.98,
        child: Material(
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openProduct(context, ref, p),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dark ? const Color(0xFF4A3D1E) : const Color(0xFFF0DDB0), width: 1.5),
                gradient: LinearGradient(
                  colors: dark ? const [Color(0xFF2B2416), NmColors.darkSurface] : const [Color(0xFFFFF8E8), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.6],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(fit: StackFit.expand, children: [
                        NetImage(p.image, width: 300),
                        if (p.off > 0) Positioned(left: 8, top: 8, child: OffTag(off: p.off)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                          decoration: BoxDecoration(color: NmColors.deal, borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(l.dodBadge.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 7),
                        Text(p.nameIn(locale), maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleMedium!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
                          Text(rupees(p.price), style: t.titleMedium!.copyWith(fontSize: 20)),
                          if (p.off > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(rupees(p.mrp!), style: t.bodySmall!.copyWith(fontSize: 13, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w400)),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        const FlipCountdown(),
                        const SizedBox(height: 10),
                        Text('🔥 ${few ? l.dodOnlyLeft(p.stock) : l.dodSellingFast}',
                            style: const TextStyle(color: NmColors.deal, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: urgency,
                            minHeight: 6,
                            backgroundColor: NmColors.deal.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(NmColors.deal),
                          ),
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

// ───────────── Shop by budget ─────────────

class BudgetCards extends StatelessWidget {
  const BudgetCards({super.key, required this.all});

  final List<Product> all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      (k: l.budgetUnder, v: rupees(199), href: '/shop?max_price=199', n: all.where((p) => p.price <= 199).length,
          tint: dark ? NmColors.brandDark : NmColors.brandSoft),
      (k: l.budgetUnder, v: rupees(499), href: '/shop?max_price=499', n: all.where((p) => p.price <= 499).length,
          tint: dark ? const Color(0xFF3A2F17) : const Color(0xFFFDF1DC)),
      (k: l.budgetUnder, v: rupees(999), href: '/shop?max_price=999', n: all.where((p) => p.price <= 999).length,
          tint: dark ? const Color(0xFF3A1A1E) : const Color(0xFFF6E3E5)),
      (k: l.budgetPremium, v: '${rupees(1000)}+', href: '/shop?min_price=1000', n: all.where((p) => p.price >= 1000).length,
          tint: dark ? const Color(0xFF2A2B27) : const Color(0xFFEDEDE7)),
    ].where((c) => c.n > 0).toList();
    if (cards.length < 2) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Row(
        children: [
          for (final c in cards)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PressScale(
                child: Material(
                  color: c.tint,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go(c.href),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 118),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.k.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(c.v, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18)),
                          const SizedBox(height: 6),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(l.itemsCount(c.n), style: TextStyle(color: scheme.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            Icon(Icons.chevron_right_rounded, size: 15, color: scheme.primary),
                          ]),
                        ],
                      ),
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

// ───────────── Footer ─────────────

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final faint = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(homeGutter, 34, homeGutter, 24),
      child: Column(children: [
        Text('Nirmal Mart',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: faint.withValues(alpha: 0.3))),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context).madeWith,
            textAlign: TextAlign.center, style: TextStyle(color: faint.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ───────────── Loading placeholders ─────────────

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(homeGutter, 26, homeGutter, 14),
            child: Skeleton(child: SkeletonBox(width: 170, height: 20)),
          ),
          SizedBox(
            height: 2 * CategoryTiles.tileHeight(context) + 12,
            child: Skeleton(
              child: GridView.count(
                crossAxisCount: 2,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: homeGutter),
                mainAxisSpacing: 10,
                crossAxisSpacing: 12,
                childAspectRatio: CategoryTiles.tileHeight(context) / 80,
                children: [
                  for (var i = 0; i < 10; i++)
                    const Column(children: [
                      SkeletonBox(width: 80, height: 80, radius: 22),
                      SizedBox(height: 8),
                      SkeletonBox(width: 56, height: 10),
                    ]),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(homeGutter, 24, homeGutter, 0),
            child: Skeleton(child: SkeletonBox(height: 156, radius: 24)),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: homeGutter),
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                const Padding(padding: EdgeInsets.only(right: _gap), child: SizedBox(width: 150, child: ProductCardSkeleton())),
            ]),
          ),
        ],
      );
}
