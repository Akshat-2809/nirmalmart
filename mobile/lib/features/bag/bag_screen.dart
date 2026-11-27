import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/cart/cart.dart';
import '../../core/catalog/catalog.dart';
import '../../core/catalog/models.dart';
import '../../core/catalog/product_detail.dart';
import '../../core/catalog/recent_and_pincode.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/wishlist/wishlist.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/pincode_sheet.dart';
import '../../shared/press_scale.dart';
import '../../shared/product_card.dart';
import '../../shared/skeleton.dart';
import '../home/home_sections.dart' show ProductRail;

const _gutter = 16.0;

/// The bag: free-delivery progress, delivery date, items (quantity, remove with Undo, move to
/// wishlist, stock warnings), products that complete free delivery, price details and Checkout.
class BagScreen extends ConsumerStatefulWidget {
  const BagScreen({super.key});

  @override
  ConsumerState<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends ConsumerState<BagScreen> {
  final _detailsKey = GlobalKey();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prices and stock may have changed since things were added
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(cartProvider.future).catchError((_) => Cart.empty);
      if (mounted) ref.read(cartProvider.notifier).refresh();
    });
  }

  /// Scrolls to the price breakdown (built only once it's near the screen, so head for the end first)
  Future<void> _toDetails() async {
    final still = MediaQuery.disableAnimationsOf(context);
    if (_detailsKey.currentContext == null && _scroll.hasClients) {
      for (var i = 0; i < 10 && _detailsKey.currentContext == null; i++) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        await WidgetsBinding.instance.endOfFrame;
      }
    }
    final c = _detailsKey.currentContext;
    if (c != null && c.mounted) {
      await Scrollable.ensureVisible(c, alignment: 0.1, duration: still ? Duration.zero : const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  void _checkout() {
    final signedIn = ref.read(authProvider).value != null;
    context.push(signedIn ? '/checkout' : '/login?from=${Uri.encodeComponent('/checkout')}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cartQ = ref.watch(cartProvider);
    final cart = cartQ.value;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final Widget body;
    if (cart == null) {
      body = const _BagSkeleton();
    } else if (cart.items.isEmpty) {
      body = const _EmptyBag();
    } else {
      final need = AppConfig.freeDeliveryThreshold - cart.subtotal;
      body = RefreshIndicator(
        onRefresh: () => ref.read(cartProvider.notifier).refresh(),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: _gutter), child: _FreeDelivery(subtotal: cart.subtotal)),
            const _DeliveryLine(),
            for (var i = 0; i < cart.items.length; i++) _Line(key: ValueKey(cart.items[i].productId), item: cart.items[i], index: i),
            if (need > 0) _FillTheGap(need: need, inBag: {for (final i in cart.items) i.productId}),
            KeyedSubtree(key: _detailsKey, child: _PriceDetails(cart: cart)),
            const _Trust(),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.myBag),
            Text(
              [if ((cart?.count ?? 0) > 0) l.itemsCount(cart!.count), l.myBagAlt].join(' · '),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
        body: body,
        bottomNavigationBar: cart == null || cart.items.isEmpty
            ? null
            : _CheckoutBar(cart: cart, onDetails: _toDetails, onCheckout: _checkout),
      ),
    );
  }
}

// ───────────── Free delivery + delivery date ─────────────

class _FreeDelivery extends StatelessWidget {
  const _FreeDelivery({required this.subtotal});

  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final need = AppConfig.freeDeliveryThreshold - subtotal;
    final done = need <= 0;
    final amount = rupees(need.ceil());
    final text = done ? l.freeDeliveryUnlocked : l.freeDeliveryMore(amount);
    final at = done ? -1 : text.indexOf(amount);
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: still ? Duration.zero : const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface,
        gradient: done ? LinearGradient(colors: [dark ? NmColors.brandDark : NmColors.brandSoft, scheme.surface]) : null,
        border: Border.all(color: done ? (dark ? NmColors.brandDark : const Color(0xFFB9DCC0)) : (dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(done ? Icons.celebration_rounded : Icons.local_shipping_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              at < 0
                  ? TextSpan(text: text, style: TextStyle(color: done ? NmColors.success : null, fontWeight: done ? FontWeight.w800 : null))
                  : TextSpan(children: [
                      TextSpan(text: text.substring(0, at)),
                      TextSpan(text: amount, style: const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: text.substring(at + amount.length)),
                    ]),
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ]),
        const SizedBox(height: 9),
        TweenAnimationBuilder<double>(
          tween: Tween(end: (subtotal / AppConfig.freeDeliveryThreshold).clamp(0.0, 1.0)),
          duration: still ? Duration.zero : const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(NmColors.success),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DeliveryLine extends ConsumerWidget {
  const _DeliveryLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pin = ref.watch(pincodeProvider);
    final date = pin == null ? null : ref.watch(deliveryCheckProvider(pin)).value?.date;
    return InkWell(
      onTap: () => showPincodeSheet(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_gutter, 10, _gutter - 4, 2),
        child: Row(children: [
          Icon(Icons.location_on_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              pin == null
                  ? TextSpan(text: l.deliveryEnterPin)
                  : TextSpan(text: '${l.homeDeliverTo} ', children: [
                      TextSpan(text: pin, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                      if (date != null) ...[
                        TextSpan(text: l.deliveryBy.isEmpty ? ' · ' : ' · ${l.deliveryBy} '),
                        TextSpan(text: date, style: const TextStyle(color: NmColors.success, fontWeight: FontWeight.w800)),
                      ],
                    ]),
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(pin == null ? l.pincodeCheck : l.change, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

// ───────────── One item ─────────────

class _Line extends ConsumerStatefulWidget {
  const _Line({super.key, required this.item, required this.index});

  final CartItem item;
  final int index;

  @override
  ConsumerState<_Line> createState() => _LineState();
}

class _LineState extends ConsumerState<_Line> {
  bool _busy = false;

  Future<void> _set(int q) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    final error = await ref.read(cartProvider.notifier).setQuantity(widget.item, q);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) showNmSnack(context, error);
  }

  /// Removes the line and offers Undo
  Future<void> _remove() async {
    final item = widget.item;
    final index = widget.index;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cart = ref.read(cartProvider.notifier);
    final error = await cart.setQuantity(item, 0);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.removedFromBag),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: l.undo, onPressed: () => cart.restore(item, index)),
      ));
  }

  Future<void> _moveToWishlist() async {
    final i = widget.item;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final product = Product.fromJson({
      'id': i.productId,
      'name': i.name,
      'name_mr': i.nameMr,
      'slug': i.slug,
      'price': i.price,
      'compare_at_price': i.mrp,
      'stock_quantity': i.stock,
      'images': [if (i.image != null) {'image_url': i.image}],
    });
    try {
      final wishlist = ref.read(wishlistProvider.notifier);
      if (!wishlist.has(i.productId)) await wishlist.toggle(product);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.wishlistError)));
      return;
    }
    final error = await ref.read(cartProvider.notifier).setQuantity(i, 0);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? l.movedToWishlist)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = widget.item;
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final marathi = locale.languageCode == 'mr' && (i.nameMr?.isNotEmpty ?? false);
    final name = marathi ? i.nameMr! : i.name;
    final alt = marathi ? i.name : i.nameMr;
    final off = i.mrp != null && i.mrp! > i.price ? ((i.mrp! - i.price) / i.mrp! * 100).round() : 0;
    final soldOut = i.stock <= 0;
    final tooMany = !soldOut && i.quantity > i.stock;
    final problem = soldOut || tooMany;

    final Widget? warning = soldOut
        ? _Warn(text: l.lineSoldOut, strong: true)
        : tooMany
            ? _Warn(text: l.lineOnlyLeft(i.stock), strong: true)
            : i.stock <= 5
                ? _Warn(text: '🔥 ${l.dodOnlyLeft(i.stock)}', strong: false)
                : null;

    void open() => context.push('/product/${i.slug}');

    return Dismissible(
      key: ValueKey('line-${i.productId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(),
      background: Container(
        margin: const EdgeInsets.fromLTRB(_gutter, 10, _gutter, 0),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: NmColors.deal, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(l.remove, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ]),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(_gutter, 10, _gutter, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: problem ? NmColors.deal.withValues(alpha: 0.6) : (dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: open,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: Opacity(opacity: soldOut ? 0.45 : 1, child: NetImage(i.image, width: 240)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: GestureDetector(
                    onTap: open,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.25)),
                    ),
                  ),
                ),
                // heart in the corner: keeps the quantity row uncluttered
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    tooltip: l.moveToWishlist,
                    onPressed: _moveToWishlist,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.favorite_border_rounded, size: 20, color: scheme.onSurfaceVariant),
                  ),
                ),
              ]),
              if (alt != null && alt.isNotEmpty)
                Text(alt, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
              const SizedBox(height: 4),
              Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
                Text(rupees(i.price * i.quantity), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
                if (off > 0) ...[
                  Text(rupees(i.mrp! * i.quantity), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, decoration: TextDecoration.lineThrough)),
                  Text(l.percentOff(off), style: const TextStyle(color: NmColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ]),
              ?warning,
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (soldOut)
                    OutlinedButton.icon(
                      onPressed: _remove,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), foregroundColor: NmColors.deal, side: const BorderSide(color: NmColors.deal)),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(l.remove),
                    )
                  else
                    _Stepper(
                      quantity: i.quantity,
                      busy: _busy,
                      canAdd: i.quantity < i.stock && i.quantity < 20,
                      onMinus: () => i.quantity <= 1 ? _remove() : _set(i.quantity - 1),
                      onPlus: () => _set(i.quantity + 1),
                      onFix: tooMany ? () => _set(i.stock) : null,
                    ),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Warn extends StatelessWidget {
  const _Warn({required this.text, required this.strong});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(text, style: TextStyle(color: NmColors.deal, fontSize: strong ? 12.5 : 11.5, fontWeight: strong ? FontWeight.w800 : FontWeight.w700)),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.quantity, required this.busy, required this.canAdd, required this.onMinus, required this.onPlus, this.onFix});

  final int quantity;
  final bool busy;
  final bool canAdd;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  /// Shown when there are more in the bag than in stock: sets it to what's left
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (onFix != null) {
      return FilledButton(
        onPressed: busy ? null : onFix,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 36), backgroundColor: NmColors.deal, padding: const EdgeInsets.symmetric(horizontal: 14)),
        child: Text(l.fixQuantity),
      );
    }
    return Container(
      height: 38,
      decoration: BoxDecoration(border: Border.all(color: dark ? NmColors.darkLine : NmColors.line, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: quantity <= 1 ? l.remove : l.removeOne,
          onPressed: busy ? null : onMinus,
          visualDensity: VisualDensity.compact,
          icon: Icon(quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, size: 19, color: scheme.primary),
        ),
        SizedBox(
          width: 22,
          child: busy
              ? Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary)))
              : Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        IconButton(
          tooltip: l.addOne,
          onPressed: busy || !canAdd ? null : onPlus,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.add_rounded, size: 19, color: canAdd ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4)),
        ),
      ]),
    );
  }
}

// ───────────── Products that complete free delivery ─────────────

class _FillTheGap extends ConsumerWidget {
  const _FillTheGap({required this.need, required this.inBag});

  final double need;
  final Set<int> inBag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(allProductsProvider).value ?? const <Product>[];
    // each one covers the gap on its own; cheapest first
    final picks = ([for (final p in all) if (!p.soldOut && !inBag.contains(p.id) && p.price >= need) p]..sort((a, b) => a.price.compareTo(b.price))).take(8).toList();
    if (picks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.fillGapTitle(rupees(need.ceil())), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
            Text(l.fillGapBody, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5)),
          ]),
        ),
        ProductRail(products: picks, cardWidth: 142),
      ]),
    );
  }
}

// ───────────── Price details ─────────────

class _PriceDetails extends StatelessWidget {
  const _PriceDetails({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget row(String a, String b, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(a, style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.85)))),
            Text(b, style: TextStyle(fontSize: 14, fontWeight: color != null ? FontWeight.w700 : FontWeight.w500, color: color)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(_gutter, 22, _gutter, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.priceDetails, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        row(l.mrpItems(cart.count), rupees(cart.mrpTotal)),
        if (cart.savings > 0) row(l.discount, '−${rupees(cart.savings)}', color: NmColors.success),
        row(l.deliveryLabel, cart.shipping == 0 ? l.free : rupees(cart.shipping), color: cart.shipping == 0 ? NmColors.success : null),
        const SizedBox(height: 6),
        CustomPaint(painter: _Dashes(color: dark ? NmColors.darkLine : const Color(0xFFD5D7CF)), child: const SizedBox(height: 1, width: double.infinity)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(l.total, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          Text(rupees(cart.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        if (cart.tax > 0)
          Text(l.includesGst(priceExact(cart.tax)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        if (cart.savings > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: dark ? NmColors.brandDark : NmColors.brandSoft, borderRadius: BorderRadius.circular(12)),
            child: Text('🎉 ${l.savingOnOrder(rupees(cart.savings))}',
                textAlign: TextAlign.center,
                style: TextStyle(color: dark ? NmColors.brandOnDark : NmColors.brandDark, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ]),
    );
  }
}

class _Dashes extends CustomPainter {
  _Dashes({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), p);
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 14, _gutter, 0),
      child: Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
        item(Icons.lock_outline_rounded, l.secureCheckout),
        item(Icons.qr_code_2_rounded, l.payByUpi),
        item(Icons.autorenew_rounded, l.fiveDayReturns),
      ]),
    );
  }
}

// ───────────── Bottom bar ─────────────

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart, required this.onDetails, required this.onCheckout});

  final Cart cart;
  final VoidCallback onDetails;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final blocked = cart.problems.isNotEmpty;
    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 10, _gutter, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (blocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 17, color: NmColors.deal),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l.fixBagFirst, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w700, fontSize: 12.5))),
                ]),
              ),
            Row(children: [
              InkWell(
                onTap: onDetails,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(rupees(cart.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(l.viewDetails, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ]),
                ),
              ),
              Expanded(
                child: PressScale(
                  scale: 0.98,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [if (!blocked) BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: FilledButton(
                      onPressed: blocked ? null : onCheckout,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(l.checkout, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ───────────── Empty and loading ─────────────

class _EmptyBag extends ConsumerWidget {
  const _EmptyBag();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wished = ref.watch(wishlistProvider).value?.length ?? 0;
    final popular = (ref.watch(trendingProductsProvider).value ?? const <Product>[]).take(8).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
        child: Column(children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 56, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(l.bagEmpty, textAlign: TextAlign.center, style: t.headlineSmall!.copyWith(fontSize: 21, fontWeight: FontWeight.w800)),
          Text(l.bagEmptyAlt, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 8),
          Text(l.bagEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.go('/shop'),
            style: FilledButton.styleFrom(minimumSize: const Size(210, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.startShopping), const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 20)]),
          ),
        ]),
      ),
      if (wished > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 0),
          child: Material(
            color: dark ? const Color(0xFF341B1A) : const Color(0xFFFFF5F3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: dark ? const Color(0xFF5A2A26) : const Color(0xFFF7D9D3)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.go('/wishlist'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.favorite_rounded, color: NmColors.deal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.inYourWishlist(wished), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                  Text(l.view, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        ),
      if (popular.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 26, _gutter, 10),
          child: Text('🔥 ${l.popularNow}', style: t.titleMedium!.copyWith(fontSize: 16)),
        ),
        ProductRail(products: popular, cardWidth: 142),
      ],
    ]);
  }
}

class _BagSkeleton extends StatelessWidget {
  const _BagSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(_gutter),
        child: Skeleton(
          child: Column(children: [
            SkeletonBox(height: 64, radius: 18),
            SizedBox(height: 14),
            SkeletonBox(height: 112, radius: 20),
            SizedBox(height: 10),
            SkeletonBox(height: 112, radius: 20),
          ]),
        ),
      );
}
