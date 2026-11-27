import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/cart/cart.dart';
import '../../core/catalog/product_detail.dart';
import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/press_scale.dart';
import '../../shared/skeleton.dart';
import 'address_sheet.dart';

const _gutter = 16.0;

/// Checkout on one page: delivery address, items, UPI payment, summary, Place order.
/// Only reachable when signed in (the router sends guests to Sign in first).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _addressId;
  final _notes = TextEditingController();
  bool _placing = false;
  bool _askedForAddress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(cartProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Address? _selected(List<Address> all) {
    if (all.isEmpty) return null;
    return all.where((a) => a.id == _addressId).firstOrNull ?? all.where((a) => a.isDefault).firstOrNull ?? all.first;
  }

  Future<void> _addAddress({required bool first}) async {
    final a = await showAddressSheet(context, firstAddress: first);
    if (a != null && mounted) setState(() => _addressId = a.id);
  }

  Future<void> _pickAddress(List<Address> all) async {
    final current = _selected(all)?.id;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressPicker(addresses: all, selected: current),
    );
    if (!mounted) return;
    if (picked is int) setState(() => _addressId = picked);
    if (picked == 'new') _addAddress(first: false);
  }

  Future<void> _place(Address address) async {
    final l = AppLocalizations.of(context);
    setState(() => _placing = true);
    HapticFeedback.mediumImpact();
    try {
      final order = await placeOrder(ref, addressId: address.id, notes: _notes.text);
      if (!mounted) return;
      // replaces Checkout, so Back can't place the same order twice
      context.go('/order/${order.id}/placed', extra: order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ref.read(cartProvider.notifier).refresh(); // stock or prices may have changed
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage(e, fallback: l.orderFailed)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: l.viewBag, onPressed: () => context.pop()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cart = ref.watch(cartProvider).value;
    final addressesQ = ref.watch(addressesProvider);
    final addresses = addressesQ.value;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // First order: no saved address yet, so open the form straight away (once)
    if (addresses != null && addresses.isEmpty && !_askedForAddress) {
      _askedForAddress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _addAddress(first: true) : null);
    }

    final address = addresses == null ? null : _selected(addresses);
    final Widget body;
    if (cart == null || (addresses == null && !addressesQ.hasError)) {
      body = const _Skeleton();
    } else if (cart.items.isEmpty) {
      body = _Empty(onShop: () => context.go('/shop'));
    } else {
      body = ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: [
          _Section(
            title: l.deliverToCaps,
            action: address == null ? null : l.change,
            onAction: address == null ? null : () => _pickAddress(addresses!),
            child: addressesQ.hasError
                ? _Retry(text: l.addressesError, onRetry: () => ref.invalidate(addressesProvider))
                : address == null
                    ? _AddAddressButton(onTap: () => _addAddress(first: true))
                    : _AddressCard(address: address),
          ),
          _Section(
            title: l.itemsCaps(cart.count),
            action: l.editBag,
            onAction: () => context.canPop() ? context.pop() : context.go('/bag'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 62,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final i in cart.items) _Thumb(item: i),
                ]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.deliveryInstructions,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  counterText: '',
                ),
              ),
            ]),
          ),
          _Section(title: l.paymentCaps, child: const _UpiMethod()),
          _Section(child: _Summary(cart: cart)),
        ],
      );
    }

    final problems = cart?.problems ?? const [];
    final canPlace = cart != null && cart.items.isNotEmpty && address != null && problems.isEmpty && !_placing;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.checkout),
            Text(
              [l.checkoutAlt, if ((cart?.count ?? 0) > 0) l.itemsCount(cart!.count)].join(' · '),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
        body: body,
        bottomNavigationBar: cart == null || cart.items.isEmpty
            ? null
            : _PlaceBar(
                total: cart.total,
                busy: _placing,
                enabled: canPlace,
                hint: problems.isNotEmpty ? l.fixBagFirst : (address == null && addresses != null ? l.addAddressFirst : null),
                onPlace: () => _place(address!),
              ),
      ),
    );
  }
}

// ───────────── Pieces ─────────────

class _Section extends StatelessWidget {
  const _Section({this.title, this.action, this.onAction, required this.child});

  final String? title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: Text(title!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: scheme.onSurfaceVariant)),
              ),
              if (action != null)
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(action!, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
            ]),
          ),
        child,
      ]),
    );
  }
}

IconData _labelIcon(String label) => switch (label.toLowerCase()) {
      'work' => Icons.work_outline_rounded,
      'other' => Icons.location_on_outlined,
      _ => Icons.home_outlined,
    };

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = address;
    final scheme = Theme.of(context).colorScheme;
    final date = ref.watch(deliveryCheckProvider(a.pincode)).value;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(_labelIcon(a.label), color: scheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
            Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            _Tag(text: a.label.toUpperCase()),
          ]),
          const SizedBox(height: 3),
          Text('${a.oneLine} · ${a.phone}', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8), fontSize: 13, height: 1.4)),
          if (date?.date != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('🚚 ${l.pincodeDeliveryBy(date!.date!)}', style: const TextStyle(color: NmColors.success, fontWeight: FontWeight.w700, fontSize: 12.5)),
            )
          else if (date?.unserviceable ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.pincodeUnserviceable, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
        ]),
      ),
    ]);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22252B) : NmColors.muted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _AddAddressButton extends StatelessWidget {
  const _AddAddressButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.add_location_alt_outlined),
      label: Text(l.addDeliveryAddress),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600))),
        TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).tryAgain)),
      ]);
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 6),
      child: Semantics(
        label: '${item.name} × ${item.quantity}',
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
            ),
            clipBehavior: Clip.antiAlias,
            child: NetImage(item.image, width: 140),
          ),
          if (item.quantity > 1)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : NmColors.ink,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
                child: Text('${item.quantity}', style: TextStyle(color: dark ? NmColors.ink : Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _UpiMethod extends StatelessWidget {
  const _UpiMethod();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        selected: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: dark ? 0.12 : 0.05),
            border: Border.all(color: scheme.primary, width: 1.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.qr_code_2_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('UPI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text(l.upiApps, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ]),
            ),
            Icon(Icons.radio_button_checked_rounded, color: scheme.primary),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: dark ? const Color(0xFF2B2416) : const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12)),
        child: Text(l.payAfterPlacing, style: TextStyle(fontSize: 12.5, height: 1.45, color: scheme.onSurface.withValues(alpha: 0.85))),
      ),
    ]);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget row(String a, String b, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(a, style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.85)))),
            Text(b, style: TextStyle(fontSize: 14, fontWeight: color != null ? FontWeight.w700 : FontWeight.w500, color: color)),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      row(l.itemsLabel(cart.count), rupees(cart.subtotal)),
      if (cart.savings > 0) row(l.youSavedLabel, rupees(cart.savings), color: NmColors.success),
      row(l.deliveryLabel, cart.shipping == 0 ? l.free : rupees(cart.shipping), color: cart.shipping == 0 ? NmColors.success : null),
      const Divider(height: 18),
      Row(children: [
        Expanded(child: Text(l.toPay, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
        Text(rupees(cart.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ]),
      if (cart.tax > 0) Text(l.includesGst(priceExact(cart.tax)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
    ]);
  }
}

class _PlaceBar extends StatelessWidget {
  const _PlaceBar({required this.total, required this.busy, required this.enabled, required this.onPlace, this.hint});

  final double total;
  final bool busy;
  final bool enabled;
  final VoidCallback onPlace;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 10, _gutter, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(hint!, textAlign: TextAlign.center, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            PressScale(
              scale: 0.98,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [if (enabled) BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: FilledButton(
                  onPressed: enabled ? onPlace : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  child: busy
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text(l.placingOrder),
                        ])
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(l.placeOrder(rupees(total)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(l.agreeTerms, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

/// Saved addresses to choose from, plus "Add new address"
class _AddressPicker extends StatelessWidget {
  const _AddressPicker({required this.addresses, required this.selected});

  final List<Address> addresses;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(l.chooseAddress, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          ),
          for (final a in addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: a.id == selected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: a.id == selected ? scheme.primary : NmColors.line, width: a.id == selected ? 1.6 : 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(a.id),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(a.id == selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: a.id == selected ? scheme.primary : scheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            _Tag(text: a.label.toUpperCase()),
                          ]),
                          const SizedBox(height: 2),
                          Text('${a.oneLine} · ${a.phone}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.35)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop('new'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.addNewAddress),
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 44, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(l.bagEmpty, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 18),
          FilledButton(onPressed: onShop, style: FilledButton.styleFrom(minimumSize: const Size(200, 50)), child: Text(l.startShopping)),
        ]),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(), // just a placeholder; clipped on short screens
        padding: EdgeInsets.all(_gutter),
        child: Skeleton(
          child: Column(children: [
            SkeletonBox(height: 120, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 140, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 120, radius: 20),
          ]),
        ),
      );
}

