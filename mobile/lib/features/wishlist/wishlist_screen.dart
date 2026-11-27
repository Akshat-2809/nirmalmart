import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/cart/cart.dart';
import '../../core/catalog/models.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/wishlist/wishlist.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../core/prefs.dart';
import '../../shared/press_scale.dart';
import '../shop/shop_screen.dart' show ViewSwitch;
import '../../shared/product_card.dart';

/// Wishlist tab: saved products with Move to bag, price-drop notes, Add all to bag, Share.
/// Prices and stock are re-checked each time it opens.
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _adding = false;

  static const _viewKey = 'nm_wishlist_view';
  late bool _list = ref.read(sharedPrefsProvider).getString(_viewKey) == 'list';

  void _setView(bool list) {
    setState(() => _list = list);
    ref.read(sharedPrefsProvider).setString(_viewKey, list ? 'list' : 'grid');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(wishlistProvider.future).catchError((_) => const <Product>[]);
      if (mounted) ref.read(wishlistProvider.notifier).refresh();
    });
  }

  Future<void> _addAll(List<Product> items) async {
    final l = AppLocalizations.of(context);
    setState(() => _adding = true);
    var added = 0;
    String? error;
    for (final p in items) {
      final e = await ref.read(cartProvider.notifier).add(p);
      if (e == null) {
        added++;
      } else {
        error ??= e;
      }
    }
    if (!mounted) return;
    setState(() => _adding = false);
    if (added > 0) {
      HapticFeedback.mediumImpact();
      showNmSnack(context, l.addedToBagCount(added), action: l.viewBag, onAction: () => context.push('/bag'));
    } else if (error != null) {
      showNmSnack(context, error);
    }
  }

  Future<void> _share(List<Product> items) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final lines = [
      l.wishlistShareTitle,
      for (final p in items.take(20)) '• ${p.nameIn(locale)} — ${rupees(p.price)}\n  ${AppConfig.siteUrl}/product/${p.slug}',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: l.wishlistShareTitle));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = ref.watch(wishlistProvider);
    final items = q.value;
    final signedIn = ref.watch(authProvider.select((a) => a.value != null));
    final inBag = ref.watch(cartProvider.select((c) => {for (final i in c.value?.items ?? const <CartItem>[]) i.productId}));
    final notifier = ref.read(wishlistProvider.notifier);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(cartProvider.select((c) => c.value?.count ?? 0));

    final Widget body;
    if (items == null) {
      body = const _Skeleton();
    } else if (items.isEmpty) {
      body = _Empty(onExplore: () => context.go('/shop'));
    } else {
      final drops = items.where((p) => (notifier.savedPrice(p.id) ?? p.price) > p.price).length;
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!signedIn)
              SliverToBoxAdapter(
                child: _Banner(
                  icon: Icons.cloud_off_rounded,
                  iconColor: const Color(0xFFB45309),
                  color: dark ? const Color(0xFF2B2416) : const Color(0xFFFFF8E8),
                  border: dark ? const Color(0xFF4A3D1E) : const Color(0xFFF0DDB0),
                  text: l.wishlistGuest,
                  action: l.tabSignIn,
                  onAction: () => context.push('/login?from=${Uri.encodeComponent('/wishlist')}'),
                ),
              ),
            if (drops > 0)
              SliverToBoxAdapter(
                child: _Banner(
                  icon: Icons.trending_down_rounded,
                  iconColor: dark ? NmColors.brandOnDark : NmColors.brandDark,
                  color: dark ? NmColors.brandDark : NmColors.brandSoft,
                  text: l.priceDropBanner(drops),
                  bold: true,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.savedCount(items.length),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ViewSwitch(list: _list, onChanged: _setView),
                  ],
                ),
              ),
            ),
            if (_list)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WishCard(
                      key: ValueKey('row-${items[i].id}'),
                      product: items[i],
                      index: i,
                      savedPrice: notifier.savedPrice(items[i].id),
                      inBag: inBag.contains(items[i].id),
                      list: true,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.builder(
                  itemCount: (items.length + 1) ~/ 2,
                  itemBuilder: (_, r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final i in [r * 2, r * 2 + 1]) ...[
                            if (i == r * 2 + 1) const SizedBox(width: 12),
                            Expanded(
                              child: i < items.length
                                  ? _WishCard(
                                      key: ValueKey(items[i].id),
                                      product: items[i],
                                      index: i,
                                      savedPrice: notifier.savedPrice(items[i].id),
                                      inBag: inBag.contains(items[i].id),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final toAdd = (items ?? const <Product>[]).where((p) => !p.soldOut && !inBag.contains(p.id)).toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: scheme.surface,
          automaticallyImplyLeading: false,
          shape: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.tabWishlist,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                [l.wishlistAlt, if (items != null && items.isNotEmpty) l.savedCount(items.length)].join(' · '),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            if (items != null && items.isNotEmpty)
              IconButton(tooltip: l.share, onPressed: () => _share(items), icon: const Icon(Icons.share_outlined)),
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
            const SizedBox(width: 4),
          ],
        ),
        body: body,
        bottomNavigationBar: toAdd.length < 2
            ? null
            : Material(
                color: scheme.surface,
                elevation: 8,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.itemsCount(toAdd.length), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                          Text(
                            rupees(toAdd.fold<double>(0, (s, p) => s + p.price)),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _adding ? null : () => _addAll(toAdd),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _adding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Icon(Icons.shopping_bag_outlined, size: 20),
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.addAllToBag)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _WishCard extends ConsumerStatefulWidget {
  const _WishCard({
    super.key,
    required this.product,
    required this.index,
    required this.savedPrice,
    required this.inBag,
    this.list = false,
  });

  /// A row (big photo left, details right) instead of a grid tile
  final bool list;

  final Product product;
  final int index;
  final double? savedPrice;
  final bool inBag;

  @override
  ConsumerState<_WishCard> createState() => _WishCardState();
}

class _WishCardState extends ConsumerState<_WishCard> {
  bool _busy = false;

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final p = widget.product;
    final i = widget.index;
    final messenger = ScaffoldMessenger.of(context);
    final wishlist = ref.read(wishlistProvider.notifier);
    HapticFeedback.selectionClick();
    try {
      await wishlist.remove(p);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.wishlistError)));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.removedFromWishlist),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: l.undo, onPressed: () => wishlist.restore(p, i)),
        ),
      );
  }

  /// Into the bag and off the wishlist
  Future<void> _moveToBag() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final error = await ref.read(cartProvider.notifier).add(widget.product);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      showNmSnack(context, error);
      return;
    }
    HapticFeedback.lightImpact();
    try {
      await ref.read(wishlistProvider.notifier).remove(widget.product);
    } catch (_) {}
    if (mounted) showNmSnack(context, l.movedToBag, action: l.viewBag, onAction: () => context.push('/bag'));
  }

  /// List view: photo on the left, name, price, price drop, remove and the bag button on the right
  Widget _row(BuildContext context, AppLocalizations l, Product p, String? alt, double drop, Widget button) {
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                        Opacity(
                          opacity: p.soldOut ? 0.45 : 1,
                          child: NetImage(p.image, width: NetImage.cardWidth),
                        ),
                        if (p.off >= 10 && !p.soldOut) Positioned(left: 6, top: 6, child: OffTag(off: p.off)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                p.nameIn(locale),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.25),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              tooltip: l.removeFromWishlist,
                              onPressed: _remove,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.favorite_rounded, size: 20, color: NmColors.deal),
                            ),
                          ),
                        ],
                      ),
                      if (alt != null)
                        Text(
                          alt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
                        ),
                      const SizedBox(height: 4),
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
                      if (drop > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF173323) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '↓ ${l.priceDropped(rupees(drop))}',
                              style: const TextStyle(color: NmColors.success, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      const Spacer(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(constraints: const BoxConstraints(minWidth: 140, maxWidth: 170), child: button),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.product;
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final alt = p.altNameIn(locale);
    final drop = widget.savedPrice != null && widget.savedPrice! > p.price ? widget.savedPrice! - p.price : 0.0;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    final Widget button;
    if (p.soldOut) {
      button = FilledButton.tonal(
        onPressed: null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(38), shape: shape),
        child: Text(l.outOfStock),
      );
    } else if (widget.inBag) {
      button = OutlinedButton.icon(
        onPressed: () => context.push('/bag'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(38),
          shape: shape,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          padding: EdgeInsets.zero,
        ),
        icon: const Icon(Icons.check_rounded, size: 17),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.inYourBag)),
      );
    } else {
      button = FilledButton.icon(
        onPressed: _busy ? null : _moveToBag,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(38), shape: shape, padding: EdgeInsets.zero),
        icon: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.shopping_bag_outlined, size: 17),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.moveToBag)),
      );
    }

    if (widget.list) return _row(context, l, p, alt, drop, button);

    return PressScale(
      scale: 0.98,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openProduct(context, ref, p),
          child: Ink(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: p.soldOut ? 0.45 : 1,
                          child: NetImage(p.image, width: NetImage.cardWidth),
                        ),
                        if (p.off >= 10 && !p.soldOut) Positioned(left: 6, top: 6, child: OffTag(off: p.off)),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: IconButton(
                            tooltip: l.removeFromWishlist,
                            onPressed: _remove,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.94),
                              fixedSize: const Size(30, 30),
                              minimumSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.favorite_rounded, size: 18, color: NmColors.deal),
                          ),
                        ),
                        if (p.soldOut)
                          Positioned(
                            left: 6,
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                l.outOfStock,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: NmColors.inkSoft),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.nameIn(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.25),
                ),
                if (alt != null)
                  Text(
                    alt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                const Spacer(),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 5,
                  children: [
                    Text(rupees(p.price), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 15.5)),
                    if (p.off > 0)
                      Text(
                        rupees(p.mrp!),
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
                if (drop > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF173323) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '↓ ${l.priceDropped(rupees(drop))}',
                          style: const TextStyle(color: NmColors.success, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                button,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.iconColor,
    required this.color,
    required this.text,
    this.border,
    this.action,
    this.onAction,
    this.bold = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color color;
  final Color? border;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final bool bold;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: border == null ? null : Border.all(color: border!),
    ),
    // the button sits under the message, so long text never gets squeezed on small phones
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 20, color: iconColor)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? iconColor : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '$action →',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: NmColors.deal.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, size: 56, color: NmColors.deal),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.wishlistEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          l.wishlistEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton(
            onPressed: onExplore,
            style: FilledButton.styleFrom(
              minimumSize: const Size(210, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(l.exploreProducts),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: ProductCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: ProductCardSkeleton()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ProductCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: ProductCardSkeleton()),
          ],
        ),
      ],
    ),
  );
}
