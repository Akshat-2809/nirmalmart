import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/skeleton.dart';
import 'order_widgets.dart';
import 'pay_sheet.dart';

enum _Filter { all, active, delivered, cancelled }

/// My orders: newest first, with All / Active / Delivered / Cancelled, and Pay now on unpaid orders
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _Filter _filter = _Filter.all;

  bool _keeps(Order o) => switch (_filter) {
        _Filter.all => true,
        _Filter.active => !o.cancelled && (o.status != 'delivered' || o.hasOpenReturn),
        _Filter.delivered => o.status == 'delivered',
        _Filter.cancelled => o.cancelled,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = ref.watch(ordersProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final all = q.value;

    final Widget body;
    if (q.hasError && all == null) {
      body = _Message(icon: Icons.wifi_off_rounded, title: l.loadError, body: l.loadErrorBody, button: l.tryAgain, onButton: () => ref.invalidate(ordersProvider));
    } else if (all == null) {
      body = const _ListSkeleton();
    } else if (all.isEmpty) {
      body = _Message(icon: Icons.receipt_long_outlined, title: l.noOrders, body: l.noOrdersBody, button: l.startShopping, onButton: () => context.go('/shop'));
    } else {
      final shown = all.where(_keeps).toList();
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(ordersProvider.future).then((_) {}, onError: (_) {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(l.noOrdersHere, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            for (final o in shown) _OrderTile(order: o),
          ],
        ),
      );
    }

    final labels = {_Filter.all: l.allProducts, _Filter.active: l.ordersActive, _Filter.delivered: l.stDelivered, _Filter.cancelled: l.stCancelled};
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.myOrders),
            Text(
              [l.myOrdersAlt, if (all != null && all.isNotEmpty) l.ordersCount(all.length)].join(' · '),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
          bottom: all == null || all.isEmpty
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)))),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      children: [
                        for (final f in _Filter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(labels[f]!),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                              showCheckmark: false,
                              selectedColor: dark ? Colors.white : NmColors.ink,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _filter == f ? (dark ? NmColors.ink : Colors.white) : Theme.of(context).colorScheme.onSurface,
                              ),
                              shape: const StadiumBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        body: body,
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final line = dark ? NmColors.darkLine : const Color(0xFFF0F0EC);

    // One line on where it's at
    final (IconData icon, Color color, String text) = o.cancelled
        ? (Icons.cancel_outlined, scheme.onSurfaceVariant, _cancelLine(l, o))
        : o.hasOpenReturn
            ? (Icons.autorenew_rounded, const Color(0xFF92400E), l.returnInProgressLine)
            : switch (o.status) {
                'delivered' => (
                    Icons.check_circle_outline_rounded,
                    NmColors.success,
                    o.canReturn
                        ? l.deliveredReturnUntil(shortDate(context, o.deliveredAt ?? o.createdAt), shortDate(context, o.returnUntil!))
                        : l.deliveredOn(shortDate(context, o.deliveredAt ?? o.createdAt)),
                  ),
                'shipped' => (Icons.local_shipping_outlined, const Color(0xFF1D4ED8), o.trackingStatus != null ? _titleCase(o.trackingStatus!) : l.onTheWay),
                'processing' => (Icons.inventory_2_outlined, scheme.primary, l.beingPacked),
                _ => (Icons.schedule_rounded, scheme.primary, l.orderConfirmedLine),
              };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/account/orders/${o.id}', extra: o),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.number, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${placedWhen(context, o.createdAt)} · ${l.itemsCount(o.itemCount)}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ]),
                ),
                const SizedBox(width: 8),
                Flexible(child: OrderBadge(order: o)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (final i in o.items.take(3))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: line)),
                      clipBehavior: Clip.antiAlias,
                      child: NetImage(i.image, width: 120),
                    ),
                  ),
                if (o.items.length > 3)
                  Text(l.plusMore(o.items.length - 3), style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12)),
                const Spacer(),
                Text(rupees(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
              const SizedBox(height: 10),
              if (o.awaitingPayment)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                  decoration: BoxDecoration(color: dark ? const Color(0xFF3A2F17) : const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.schedule_rounded, size: 18, color: dark ? NmColors.goldSoft : const Color(0xFF92400E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l.paymentPending,
                          style: TextStyle(color: dark ? NmColors.goldSoft : const Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                    FilledButton(
                      onPressed: () => showPaySheet(context, o),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: Text(l.payNow),
                    ),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: line))),
                  child: Row(children: [
                    Icon(icon, size: 17, color: color),
                    const SizedBox(width: 6),
                    Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.8)))),
                    Text('${l.details} ›', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

String _cancelLine(AppLocalizations l, Order o) => switch (o.paymentStatus) {
      'refunded' => l.cancelledRefunded(rupees(o.total)),
      'refund_pending' => l.cancelledRefundPending(rupees(o.total)),
      _ => l.cancelledNothingCharged,
    };

String _titleCase(String s) => s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

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
    return ListView(padding: const EdgeInsets.fromLTRB(32, 64, 32, 32), children: [
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 44, color: scheme.primary),
        ),
      ),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
      const SizedBox(height: 6),
      Text(body, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      Center(child: FilledButton(onPressed: onButton, style: FilledButton.styleFrom(minimumSize: const Size(200, 50)), child: Text(button))),
    ]);
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Skeleton(
          child: Column(children: [
            SkeletonBox(height: 150, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 150, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 150, radius: 20),
          ]),
        ),
      );
}
