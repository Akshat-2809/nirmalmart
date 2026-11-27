import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/cart/cart.dart';
import '../../core/catalog/models.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/product_card.dart';
import '../../shared/contact_sheet.dart';
import '../../shared/whatsapp.dart';
import 'order_sheets.dart';
import 'order_widgets.dart';
import 'pay_sheet.dart';

/// One order: payment (if still due), status timeline and tracking, returns, items, bill, address,
/// and Cancel / Return or exchange / Buy again / Need help / Rate items.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.initial});

  final int orderId;

  /// From the list, shown while the latest copy loads
  final Order? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final q = ref.watch(orderProvider(orderId));
    final o = q.value ?? initial;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final Widget body;
    if (o == null) {
      body = q.hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.loadError, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => ref.invalidate(orderProvider(orderId)), child: Text(l.tryAgain)),
                ]),
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(orderProvider(orderId).future).then((_) {}, onError: (_) {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            if (o.awaitingPayment) _PayCard(order: o),
            if (o.cancelled) _CancelledCard(order: o) else _StatusCard(order: o),
            if (o.canReturn) _ReturnWindow(until: o.returnUntil!),
            for (final r in o.returns) _ReturnCard(order: o, ret: r),
            _Items(order: o),
            if (o.shipTo != null) _Address(shipTo: o.shipTo!),
            _Actions(order: o),
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
          title: o == null
              ? Text(l.orderDetails)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onLongPress: () async {
                      await Clipboard.setData(ClipboardData(text: o.number));
                      if (context.mounted) showNmSnack(context, l.orderIdCopied);
                    },
                    child: Text(o.number, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    o.status == 'delivered' && o.deliveredAt != null
                        ? l.deliveredOn(shortDate(context, o.deliveredAt!))
                        : l.placedOn(placedWhen(context, o.createdAt)),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ]),
        ),
        body: body,
      ),
    );
  }
}

/// The WhatsApp text for "I've paid" (same wording as the website)
String paidMessage(Order o) => [
      'Hello Nirmal Mart, I have paid for my order.',
      'Order ID: ${o.number}',
      'Amount: ${o.total % 1 == 0 ? rupees(o.total) : priceExact(o.total)}',
      if (o.customerName != null) 'Name: ${o.customerName}',
      'Payment screenshot attached.',
    ].join('\n');

class _PayCard extends StatelessWidget {
  const _PayCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final amount = order.total % 1 == 0 ? rupees(order.total) : priceExact(order.total);
    return OrderCard(
      color: dark ? const Color(0xFF2B2416) : const Color(0xFFFFF8E8),
      border: dark ? const Color(0xFF4A3D1E) : const Color(0xFFF0DDB0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.paymentPending.toUpperCase(), style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
        const SizedBox(height: 2),
        Text(l.payToConfirm(amount), style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(l.payToConfirmBody, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => showPaySheet(context, order),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.qr_code_2_rounded, size: 19),
              label: Text(l.payNow),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => openWhatsApp(context, AppConfig.paymentWhatsApp, paidMessage(order)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF128C4B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat_rounded, size: 19),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.sendProofShort)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OrderCard(
      title: l.statusCaps,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OrderTimeline(status: o.status),
        if (o.awb != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(color: dark ? const Color(0xFF1F2621) : const Color(0xFFF6F8F4), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.local_shipping_outlined, color: o.status == 'delivered' ? NmColors.success : const Color(0xFF1D4ED8)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    [if (o.trackingStatus != null) _titleCase(o.trackingStatus!) else l.onTheWay, ?o.courier].join(' · '),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  Text('AWB ${o.awb}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                ]),
              ),
              if (o.trackingUrl != null)
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(o.trackingUrl!), mode: LaunchMode.externalApplication),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: Text('${l.track} ↗'),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}

String _titleCase(String s) => s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class _CancelledCard extends StatelessWidget {
  const _CancelledCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final scheme = Theme.of(context).colorScheme;
    final refundLine = switch (o.paymentStatus) {
      'refunded' => [l.refundDone(rupees(o.total)), if (o.refundReference != null) l.upiRef(o.refundReference!)].join(' · '),
      'refund_pending' => l.refundOnTheWay(rupees(o.total)),
      _ => l.cancelledNothingCharged,
    };
    return OrderCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.cancel_outlined, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              o.cancelledAt != null ? l.cancelledOn(shortDate(context, o.cancelledAt!)) : l.stCancelled,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            if (o.cancelReason != null) Text(o.cancelReason!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 6),
            Text(refundLine,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: o.paymentStatus == 'refunded' ? NmColors.success : scheme.onSurface.withValues(alpha: 0.85))),
          ]),
        ),
      ]),
    );
  }
}

class _ReturnWindow extends StatelessWidget {
  const _ReturnWindow({required this.until});

  final DateTime until;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final days = until.difference(DateTime.now()).inHours ~/ 24;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: dark ? NmColors.brandDark : NmColors.brandSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(Icons.autorenew_rounded, size: 18, color: dark ? NmColors.brandOnDark : NmColors.brandDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            days >= 1 ? l.returnUntilDays(dayDate(context, until), days) : l.returnUntilToday(dayDate(context, until)),
            style: TextStyle(color: dark ? NmColors.brandOnDark : NmColors.brandDark, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ),
      ]),
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  const _ReturnCard({required this.order, required this.ret});

  final Order order;
  final ReturnRequest ret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final r = ret;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = {
      'requested': l.retRequested,
      'approved': l.retApproved,
      'pickup_scheduled': l.retPickupScheduled,
      'picked_up': l.retPickedUp,
      'received': l.retReceived,
      'completed': r.exchange ? l.retExchanged : l.retRefunded,
      'rejected': l.retRejected,
      'cancelled': l.stCancelled,
    };
    final step = ReturnRequest.progress.indexOf(r.status);
    final names = r.items.map((i) => i.name).whereType<String>().join(', ');
    final bad = r.status == 'rejected' || r.status == 'cancelled';
    return OrderCard(
      border: bad ? null : (dark ? const Color(0xFF4A3D1E) : const Color(0xFFF0DDB0)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(r.exchange ? Icons.swap_horiz_rounded : Icons.keyboard_return_rounded, size: 19),
          const SizedBox(width: 6),
          Expanded(
            child: Text('${r.exchange ? l.exchangeWord : l.returnWord}${names.isEmpty ? '' : ' · $names'}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bad ? (dark ? const Color(0xFF22252B) : NmColors.muted) : (dark ? const Color(0xFF3A2F17) : const Color(0xFFFEF3C7)),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(labels[r.status] ?? r.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: bad ? scheme.onSurfaceVariant : const Color(0xFFB45309))),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          [
            r.reason,
            if (!r.exchange && r.refundAmount != null && !bad) l.refundToUpi(rupees(r.refundAmount!)),
            if (r.refundReference != null) l.upiRef(r.refundReference!),
          ].join(' · '),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        ),
        if (r.adminNote?.isNotEmpty ?? false)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('“${r.adminNote}”', style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.8)))),
        if (!bad) ...[
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < ReturnRequest.progress.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(height: 5, decoration: BoxDecoration(color: i <= step ? NmColors.gold : (dark ? NmColors.darkLine : NmColors.line), borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ]),
          const SizedBox(height: 5),
          DefaultTextStyle.merge(
            style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
            child: Row(children: [
              Text(l.retRequested),
              const Spacer(),
              Text(l.retPickedUp),
              const Spacer(),
              Text(r.exchange ? l.retExchanged : l.retRefunded),
            ]),
          ),
        ],
        if (r.pickupTrackingUrl != null && r.open || r.canCancel)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, children: [
              if (r.pickupTrackingUrl != null && r.open)
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(r.pickupTrackingUrl!), mode: LaunchMode.externalApplication),
                  child: Text('${l.trackPickup} ↗'),
                ),
              if (r.canCancel)
                TextButton(
                  onPressed: () => confirmCancelReturn(context, ref, order, r),
                  style: TextButton.styleFrom(foregroundColor: NmColors.deal),
                  child: Text(l.cancelRequest),
                ),
            ]),
          ),
      ]),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final scheme = Theme.of(context).colorScheme;
    final returned = <int, int>{};
    for (final r in o.returns.where((r) => r.status != 'rejected' && r.status != 'cancelled')) {
      for (final i in r.items) {
        returned[i.orderItemId] = (returned[i.orderItemId] ?? 0) + i.quantity;
      }
    }
    Widget row(String a, String b, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(a, style: TextStyle(fontSize: 13.5, color: scheme.onSurface.withValues(alpha: 0.85)))),
            Text(b, style: TextStyle(fontSize: 13.5, color: color, fontWeight: color != null ? FontWeight.w700 : null)),
          ]),
        );
    return OrderCard(
      title: l.itemsCaps(o.itemCount),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final i in o.items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: i.slug == null ? null : () => context.push('/product/${i.slug}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 52, height: 52, child: NetImage(i.image, width: 140))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    Text(
                      [l.qtyPrice(i.quantity, rupees(i.unitPrice)), if ((returned[i.id] ?? 0) > 0) l.inReturn(returned[i.id]!)].join(' · '),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(rupees(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
            ),
          ),
        const Divider(height: 18),
        row(l.itemsLabel(o.itemCount), rupees(o.subtotal)),
        row(l.deliveryLabel, o.shipping == 0 ? l.free : rupees(o.shipping), color: o.shipping == 0 ? NmColors.success : null),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text(l.total, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          Text(rupees(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        if (o.tax > 0) Text(l.includesGst(priceExact(o.tax)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.paidBy(o.paymentStatus == 'pending' ? l.upiPending : 'UPI'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

class _Address extends StatelessWidget {
  const _Address({required this.shipTo});

  final Map<String, dynamic> shipTo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = shipTo;
    final scheme = Theme.of(context).colorScheme;
    final lines = [
      a['address_line1'],
      a['address_line2'],
      a['city'],
      '${a['state'] ?? ''} – ${a['postal_code'] ?? ''}',
    ].where((x) => x != null && '$x'.trim().isNotEmpty).join(', ');
    return OrderCard(
      title: l.deliveringToCaps,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '${a['full_name'] ?? ''}', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
          if (a['phone'] != null) TextSpan(text: ' · ${a['phone']}'),
          TextSpan(text: '\n$lines'),
        ]),
        style: TextStyle(fontSize: 13, height: 1.45, color: scheme.onSurface.withValues(alpha: 0.8)),
      ),
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.order});

  final Order order;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  bool _adding = false;

  /// Puts what's still on sale back in the bag
  Future<void> _buyAgain() async {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final ids = {for (final i in o.items) ?i.productId};
    if (ids.isEmpty) return;
    setState(() => _adding = true);
    var added = 0;
    try {
      final r = await ref.read(apiClientProvider).dio.get<Map<String, dynamic>>('/products', queryParameters: {
        'ids': ids.join(','),
        'per_page': ids.length,
      });
      final products = {for (final p in r.data!['items'] as List) (p as Map<String, dynamic>)['id'] as int: Product.fromJson(p)};
      for (final i in o.items) {
        final p = products[i.productId];
        if (p == null || p.soldOut) continue;
        final error = await ref.read(cartProvider.notifier).add(p, quantity: i.quantity.clamp(1, p.stock));
        if (error == null) added++;
      }
    } catch (e) {
      if (mounted) showNmSnack(context, errorMessage(e));
      if (mounted) setState(() => _adding = false);
      return;
    }
    if (!mounted) return;
    setState(() => _adding = false);
    if (added == 0) {
      showNmSnack(context, l.buyAgainNone);
    } else {
      showNmSnack(context, added < o.items.length ? l.buyAgainSome(added) : l.addedToBag, action: l.viewBag, onAction: () => context.push('/bag'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final buttons = <Widget>[
      if (o.canCancel)
        OutlinedButton.icon(
          onPressed: () => showCancelOrder(context, ref, o),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: shape,
            foregroundColor: NmColors.deal,
            side: BorderSide(color: NmColors.deal.withValues(alpha: 0.4)),
          ),
          icon: const Icon(Icons.close_rounded, size: 19),
          label: Text(l.cancelOrder),
        ),
      if (o.canReturn)
        OutlinedButton.icon(
          onPressed: () => showReturnSheet(context, ref, o),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape, foregroundColor: scheme.primary, side: BorderSide(color: scheme.primary)),
          icon: const Icon(Icons.autorenew_rounded, size: 19),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.returnExchange)),
        ),
      if (o.status == 'delivered')
        FilledButton.icon(
          onPressed: () => showRateSheet(context, o),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape),
          icon: const Icon(Icons.star_rounded, size: 19),
          label: Text(l.rateItems),
        ),
      if (!o.awaitingPayment && o.status != 'pending' || o.cancelled)
        OutlinedButton.icon(
          onPressed: _adding ? null : _buyAgain,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape, foregroundColor: scheme.primary, side: BorderSide(color: scheme.primary)),
          icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.replay_rounded, size: 19),
          label: Text(l.buyAgain),
        ),
      OutlinedButton.icon(
        onPressed: () => showContactSheet(context, message: l.helpMessage(o.number), emailSubject: l.helpEmailSubject(o.number)),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: shape),
        icon: const Icon(Icons.support_agent_rounded, size: 19),
        label: Text(l.needHelp),
      ),
    ];
    // two per row
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(children: [
        for (var i = 0; i < buttons.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: buttons[i]),
              if (i + 1 < buttons.length) ...[const SizedBox(width: 10), Expanded(child: buttons[i + 1])],
            ]),
          ),
      ]),
    );
  }
}
