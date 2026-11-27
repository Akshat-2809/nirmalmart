import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cart/cart.dart';
import '../core/catalog/models.dart';
import '../core/catalog/recent_and_pincode.dart';
import '../core/format.dart';
import '../core/theme/tokens.dart';
import '../core/wishlist/wishlist.dart';
import '../l10n/app_localizations.dart';
import 'net_image.dart';
import 'press_scale.dart';
import 'skeleton.dart';

void showNmSnack(BuildContext context, String text, {String? action, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 2),
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ));
}

/// Opens a product page and remembers it for "Recently viewed"
void openProduct(BuildContext context, WidgetRef ref, Product p) {
  prefetchPhoto(context, ref, p.image); // the big photo starts loading now, not when the page opens
  ref.read(recentIdsProvider.notifier).push(p.id);
  context.push('/product/${p.slug}', extra: p);
}

/// Product tile used on Home, Shop, Search and Wishlist: rounded photo with % off, heart and an ADD
/// button (– 1 + once it's in the bag), name in the app's language with the other language underneath,
/// rating, price with MRP and how much you save. Put it in a row with IntrinsicHeight so neighbours line up.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final alt = p.altNameIn(locale);
    final save = p.off > 0 ? p.mrp! - p.price : 0.0;

    return Semantics(
      label: '${p.nameIn(locale)}, ${rupees(p.price)}${p.off > 0 ? ', ${p.off}% off' : ''}',
      child: PressScale(
        scale: 0.97,
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
                          NetImage(p.image, width: 300),
                          if (p.off >= 10 || p.isFeatured)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.off >= 10) OffTag(off: p.off),
                                  if (p.off >= 10 && p.isFeatured) const SizedBox(height: 4),
                                  if (p.isFeatured) _Tag(text: l.bestseller, color: Colors.white.withValues(alpha: 0.94), ink: NmColors.ink),
                                ],
                              ),
                            ),
                          Positioned(right: 0, top: 0, child: HeartButton(product: p)),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            left: p.soldOut ? 6 : null,
                            child: p.soldOut ? _SoldOut(text: l.outOfStock) : AddButton(product: p),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nameIn(locale),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
                          if (alt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(alt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall!.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
                            ),
                          if (p.ratingCount > 0) ...[
                            const SizedBox(height: 4),
                            _Rating(value: p.rating, count: p.ratingCount),
                          ],
                          const Spacer(),
                          const SizedBox(height: 5),
                          _Price(product: p),
                          if (save > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(l.youSave(rupees(save)),
                                  style: const TextStyle(color: NmColors.success, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
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

/// Red "33% OFF" label on a product photo
class OffTag extends StatelessWidget {
  const OffTag({super.key, required this.off});

  final int off;

  @override
  Widget build(BuildContext context) =>
      _Tag(text: AppLocalizations.of(context).offTag(off), color: NmColors.deal, ink: Colors.white);
}

class _SoldOut extends StatelessWidget {
  const _SoldOut({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NmColors.inkSoft)),
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, required this.ink});

  final String text;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      );
}

class _Rating extends StatelessWidget {
  const _Rating({required this.value, required this.count});

  final double value;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(color: NmColors.success, borderRadius: BorderRadius.circular(5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, size: 11, color: Colors.white),
            ]),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text('($count)', maxLines: 1, overflow: TextOverflow.clip, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11)),
          ),
        ],
      );
}

class _Price extends StatelessWidget {
  const _Price({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 5,
      children: [
        Text(rupees(product.price), style: t.titleMedium!.copyWith(fontSize: 15.5, height: 1.15)),
        if (product.off > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(rupees(product.mrp!),
                style: t.bodySmall!.copyWith(fontSize: 11.5, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w400)),
          ),
      ],
    );
  }
}

/// ADD on the photo; once in the bag it becomes – 1 + (the – at 1 takes it out of the bag)
class AddButton extends ConsumerStatefulWidget {
  const AddButton({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends ConsumerState<AddButton> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function(CartController cart) action, {bool firstAdd = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final error = await action(ref.read(cartProvider.notifier));
    if (!mounted) return;
    setState(() => _busy = false);
    final l = AppLocalizations.of(context);
    if (error != null) {
      showNmSnack(context, error);
    } else if (firstAdd) {
      showNmSnack(context, l.addedToBag, action: l.viewBag, onAction: () => context.push('/bag'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.product;
    final item = ref.watch(cartProvider.select((c) {
      for (final i in c.value?.items ?? const <CartItem>[]) {
        if (i.productId == p.id) return i;
      }
      return null;
    }));
    final still = MediaQuery.disableAnimationsOf(context);
    const shadow = [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))];

    final Widget child;
    if (item == null) {
      child = Semantics(
        key: const ValueKey('add'),
        button: true,
        label: l.add,
        excludeSemantics: true,
        child: PressScale(
          scale: 0.9,
          child: GestureDetector(
            onTap: () => _run((c) => c.add(p), firstAdd: true),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NmColors.brand, width: 1.5),
                boxShadow: shadow,
              ),
              child: _busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: NmColors.brand))
                  : Text(l.addCaps, style: const TextStyle(color: NmColors.brand, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3)),
            ),
          ),
        ),
      );
    } else {
      Widget step(IconData icon, String label, VoidCallback onTap) => Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: _busy ? null : onTap,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 30, height: 32, child: Icon(icon, size: 18, color: Colors.white)),
            ),
          );
      child = Material(
        key: const ValueKey('stepper'),
        color: NmColors.brand,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: const [
            BoxShadow(color: Color(0x59317239), blurRadius: 10, offset: Offset(0, 4)),
          ]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              step(Icons.remove_rounded, l.removeOne, () => _run((c) => c.setQuantity(item, item.quantity - 1))),
              SizedBox(
                width: 18,
                child: Text('${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              step(Icons.add_rounded, l.addOne, () => _run((c) => c.add(p))),
            ],
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 220),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, alignment: Alignment.centerRight, child: c),
      child: child,
    );
  }
}

/// Heart on a product photo. Saves to the wishlist (on the phone for guests) with a pop.
class HeartButton extends ConsumerStatefulWidget {
  const HeartButton({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<HeartButton> {
  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    final l = AppLocalizations.of(context);
    try {
      final on = await ref.read(wishlistProvider.notifier).toggle(widget.product);
      if (mounted) showNmSnack(context, on ? l.savedToWishlist : l.removedFromWishlist);
    } catch (_) {
      if (mounted) showNmSnack(context, l.wishlistError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = ref.watch(wishlistProvider.select((w) => (w.value ?? const []).any((p) => p.id == widget.product.id)));
    final still = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      onPressed: _toggle,
      tooltip: on ? l.removeFromWishlist : l.addToWishlist,
      isSelected: on,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        minimumSize: const Size(30, 30),
        fixedSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: TweenAnimationBuilder<double>(
        key: ValueKey(on),
        tween: Tween(begin: on && !still ? 0.4 : 1, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17, color: on ? NmColors.deal : NmColors.inkSoft),
      ),
    );
  }
}

/// Grey stand-in for a [ProductCard] while loading
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: 18)),
            SizedBox(height: 10),
            SkeletonBox(height: 12, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 12, width: 90),
            SizedBox(height: 12),
            SkeletonBox(height: 16, width: 60),
          ],
        ),
      );
}
