import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/cart/cart.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/product_detail.dart';
import '../../core/catalog/recent_and_pincode.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/wishlist/wishlist.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/press_scale.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';
import '../home/home_sections.dart' show ProductRail;
import 'product_gallery.dart';
import 'product_sections.dart';

/// Product page: big swipeable photos, a white panel sliding over them with price, stock, quantity,
/// delivery date for the saved pincode, description (English / मराठी), reviews and similar products,
/// with Add to bag and Buy now always at the bottom. [initial] (the card that was tapped) shows
/// straight away while the full details load.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.slug, this.initial});

  final String slug;
  final Product? initial;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final _scroll = ScrollController();
  final _photoKey = GlobalKey();
  final _bagKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  double _bar = 0; // 0 = over the photo, 1 = solid white top bar with the name
  int _qty = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v = ((_scroll.offset - 220) / 120).clamp(0.0, 1.0);
      if ((v - _bar).abs() > 0.02 || (v != _bar && (v == 0 || v == 1))) setState(() => _bar = v);
    });
    final id = widget.initial?.id;
    if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(recentIdsProvider.notifier).push(id));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String get _here => '/product/${widget.slug}';

  Future<void> _share(Product p) async {
    final l = AppLocalizations.of(context);
    final link = '${AppConfig.siteUrl}/product/${p.slug}';
    await SharePlus.instance.share(ShareParams(
      text: l.shareText(p.nameIn(Localizations.localeOf(context)), rupees(p.price), link),
      subject: p.name,
    ));
  }

  Future<bool> _add(Product p) async {
    if (_busy) return false;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final error = await ref.read(cartProvider.notifier).add(p, quantity: _qty);
    if (!mounted) return false;
    setState(() => _busy = false);
    if (error != null) {
      showNmSnack(context, error);
      return false;
    }
    return true;
  }

  Future<void> _addToBag(Product p) async {
    if (await _add(p) && mounted) {
      _flyToBag(p);
      showNmSnack(context, AppLocalizations.of(context).addedToBag, action: AppLocalizations.of(context).viewBag, onAction: () => context.push('/bag'));
    }
  }

  Future<void> _buyNow(Product p, bool inBag) async {
    if (inBag || await _add(p)) {
      if (mounted) context.push('/checkout');
    }
  }

  /// A copy of the photo shrinks and flies into the bag icon
  void _flyToBag(Product p) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final from = _photoKey.currentContext?.findRenderObject() as RenderBox?;
    final to = _bagKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (from == null || to == null || overlay == null || !from.hasSize || !to.hasSize) return;
    final start = from.localToGlobal(from.size.center(Offset.zero));
    final end = to.localToGlobal(to.size.center(Offset.zero));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: const Cubic(0.5, 0, 0.75, 0.4),
        onEnd: () => entry.remove(),
        builder: (_, t, child) {
          final pos = Offset.lerp(start, end, t)!;
          final size = 130 * (1 - 0.8 * t);
          return Positioned(
            left: pos.dx - size / 2,
            top: pos.dy - size / 2,
            child: IgnorePointer(child: Opacity(opacity: t > 0.85 ? (1 - t) / 0.15 : 1, child: SizedBox(width: size, height: size, child: child))),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(22), child: NetImage(p.image, width: 300)),
        ),
      ),
    );
    overlay.insert(entry);
  }

  void _toReviews() {
    final c = _reviewsKey.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, alignment: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final detailQ = ref.watch(productDetailProvider(widget.slug));
    final detail = detailQ.value;
    final p = detail?.product ?? widget.initial;

    // Opened from a link without the card: remember it once the details arrive
    ref.listen(productDetailProvider(widget.slug), (prev, next) {
      final id = next.value?.product.id;
      if (id != null && prev?.value == null && widget.initial == null) ref.read(recentIdsProvider.notifier).push(id);
    });

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailQ.hasError
            ? _Problem(
                notFound: detailQ.error is DioException && (detailQ.error as DioException).response?.statusCode == 404,
                onRetry: () => ref.invalidate(productDetailProvider(widget.slug)),
              )
            : ListView(children: [
                Skeleton(child: SkeletonBox(height: _galleryHeight(context), radius: 0)),
                const Padding(padding: EdgeInsets.all(productGutter), child: ProductSkeleton()),
              ]),
      );
    }

    final locale = Localizations.localeOf(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inBag = ref.watch(cartProvider.select((c) => c.value?.quantityOf(p.id) ?? 0)) > 0;
    final maxQty = p.stock.clamp(1, 20);
    if (_qty > maxQty) _qty = maxQty;
    final related = ref.watch(relatedProductsProvider(widget.slug)).value ?? const <Product>[];
    final alt = p.altNameIn(locale);
    final category = detail?.categoryIn(locale);

    final sheet = Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, -8))],
      ),
      padding: const EdgeInsets.fromLTRB(productGutter, 22, productGutter, 0), // the 30 px overlap leaves the space below
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (category != null)
              _Chip(
                text: category.toUpperCase(),
                fg: scheme.primary,
                bg: scheme.primary.withValues(alpha: 0.12),
                onTap: detail?.categorySlug == null ? null : () => context.go('/shop?category=${detail!.categorySlug}'),
              ),
            if (p.off >= 20)
              _Chip(text: '⚡ ${l.topDeal}', fg: NmColors.deal, bg: NmColors.deal.withValues(alpha: 0.1))
            else if (p.isTrending)
              _Chip(text: '🔥 ${l.catTrendingChip}', fg: NmColors.deal, bg: NmColors.deal.withValues(alpha: 0.1)),
          ]),
          const SizedBox(height: 10),
          Semantics(header: true, child: Text(p.nameIn(locale), style: t.headlineSmall!.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.15))),
          if (alt != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(alt, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14))),
          const SizedBox(height: 10),
          if (p.ratingCount > 0)
            InkWell(
              onTap: _toReviews,
              borderRadius: BorderRadius.circular(8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: NmColors.success, borderRadius: BorderRadius.circular(7)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(p.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(width: 2),
                    const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(l.reviewsCount(p.ratingCount), style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            )
          else
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              _Chip(text: '✨ ${l.newArrival}', fg: dark ? NmColors.goldSoft : const Color(0xFF8A5A00), bg: NmColors.gold.withValues(alpha: dark ? 0.2 : 0.22)),
              Text(l.beFirstToReview, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          const SizedBox(height: 14),
          PriceBlock(product: p),
          const SizedBox(height: 14),
          StockLine(stock: p.stock),
          if (!p.soldOut) ...[
            const SizedBox(height: 14),
            QuantityRow(value: _qty, max: maxQty, onChanged: (v) => setState(() => _qty = v.clamp(1, maxQty))),
          ],
          const SizedBox(height: 18),
          const BenefitTiles(),
          const SizedBox(height: 14),
          const DeliveryCard(),
          if (detail != null) ...[
            const SizedBox(height: 24),
            AboutSection(detail: detail),
          ] else ...[
            const SizedBox(height: 24),
            const Skeleton(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 170, height: 18),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 12),
              SizedBox(height: 8),
              SkeletonBox(width: 220, height: 12),
            ])),
          ],
          const SizedBox(height: 16),
          KeyedSubtree(key: _reviewsKey, child: ReviewsSection(product: p, from: _here)),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _bar > 0.6 && !dark ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              slivers: [
                // one box, so the white panel paints over the bottom of the photo
                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ProductGallery(images: p.images, height: _galleryHeight(context), photoKey: _photoKey),
                    Transform.translate(offset: const Offset(0, -30), child: sheet),
                  ]),
                ),
                if (related.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(productGutter, 0, productGutter, 12),
                          child: Text(l.youMayAlsoLike, style: t.titleLarge!.copyWith(fontSize: 18)),
                        ),
                        ProductRail(products: related),
                      ]),
                    ),
                  ),
              ],
            ),
            Positioned(left: 0, right: 0, top: 0, child: _TopBar(
              solid: _bar,
              title: p.nameIn(locale),
              product: p,
              bagKey: _bagKey,
              onShare: () => _share(p),
            )),
          ],
        ),
        bottomNavigationBar: _BuyBar(
          product: p,
          inBag: inBag,
          busy: _busy,
          onAdd: () => inBag ? context.push('/bag') : _addToBag(p),
          onBuy: () => _buyNow(p, inBag),
        ),
      ),
    );
  }

  static double _galleryHeight(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return (s.width * 1.1).clamp(280.0, s.height * 0.55);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.fg, required this.bg, this.onTap});

  final String text;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ),
      );
}

/// Round back / share / heart / bag buttons over the photo; once scrolled, a white bar with the name
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.solid, required this.title, required this.product, required this.bagKey, required this.onShare});

  final double solid;
  final String title;
  final Product product;
  final GlobalKey bagKey;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(cartProvider.select((c) => c.value?.count ?? 0));
    final saved = ref.watch(wishlistProvider.select((w) => (w.value ?? const []).any((x) => x.id == product.id)));

    Future<void> toggleWish() async {
      HapticFeedback.selectionClick();
      try {
        final on = await ref.read(wishlistProvider.notifier).toggle(product);
        if (context.mounted) showNmSnack(context, on ? l.savedToWishlist : l.removedFromWishlist);
      } catch (_) {
        if (context.mounted) showNmSnack(context, l.wishlistError);
      }
    }

    return Material(
      color: scheme.surface.withValues(alpha: solid),
      elevation: solid > 0.95 ? 2 : 0,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, MediaQuery.paddingOf(context).top + 6, 10, 8),
        child: Row(children: [
          _Round(
            tooltip: l.authBack,
            solid: solid,
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            child: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          ),
          Expanded(
            child: Opacity(
              opacity: solid,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
          _Round(tooltip: l.share, solid: solid, onTap: onShare, child: Icon(Icons.share_outlined, color: scheme.onSurface, size: 21)),
          const SizedBox(width: 8),
          _Round(
            tooltip: saved ? l.removeFromWishlist : l.addToWishlist,
            solid: solid,
            onTap: toggleWish,
            child: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? NmColors.deal : scheme.onSurface, size: 22),
          ),
          const SizedBox(width: 8),
          _Round(
            key: bagKey,
            tooltip: count > 0 ? '${l.homeBag}, $count' : l.homeBag,
            solid: solid,
            onTap: () => context.push('/bag'),
            child: Stack(clipBehavior: Clip.none, children: [
              Icon(Icons.shopping_bag_outlined, color: scheme.onSurface, size: 22),
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
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: NmColors.deal, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
                      child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1)),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({super.key, required this.tooltip, required this.onTap, required this.child, required this.solid});

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final double solid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // white circles over the photo, fading into plain icons on the white bar
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: PressScale(
          scale: 0.9,
          child: Material(
            color: Color.lerp(scheme.surface.withValues(alpha: 0.92), Colors.transparent, solid),
            shape: const CircleBorder(),
            elevation: solid > 0.5 ? 0 : 2,
            shadowColor: Colors.black26,
            child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Center(child: child))),
          ),
        ),
      ),
    );
  }
}

/// Add to bag (Go to bag once it's in) and Buy now, always at the bottom
class _BuyBar extends StatelessWidget {
  const _BuyBar({required this.product, required this.inBag, required this.busy, required this.onAdd, required this.onBuy});

  final Product product;
  final bool inBag;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(productGutter, 12, productGutter, 12),
          child: product.soldOut
              ? FilledButton(onPressed: null, style: FilledButton.styleFrom(shape: shape), child: Text(l.outOfStock))
              : Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onAdd,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: shape,
                        side: BorderSide(color: scheme.primary, width: 1.5),
                        foregroundColor: scheme.primary,
                        textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: Icon(inBag ? Icons.check_circle_rounded : Icons.shopping_bag_outlined, size: 20),
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text(inBag ? l.goToBag : l.addToBag)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: FilledButton.icon(
                        onPressed: busy ? null : onBuy,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: shape,
                          textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Icon(Icons.bolt_rounded, size: 20),
                        label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.buyNow)),
                      ),
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.notFound, required this.onRetry});

  final bool notFound;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(notFound ? Icons.search_off_rounded : Icons.wifi_off_rounded, size: 38, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(notFound ? l.productGone : l.loadError, textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: 6),
          Text(notFound ? l.productGoneBody : l.loadErrorBody, textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: notFound ? () => context.go('/') : onRetry,
            style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
            child: Text(notFound ? l.backToShopping : l.tryAgain),
          ),
        ]),
      ),
    );
  }
}
