import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/push/push.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/product_card.dart';
import '../../shared/whatsapp.dart';

/// "Order placed!" and paying for it: UPI app (amount filled in), the store's QR (save to gallery),
/// UPI ID to copy, then payment proof on WhatsApp — same steps as the website's order page.
class OrderPlacedScreen extends ConsumerStatefulWidget {
  const OrderPlacedScreen({super.key, required this.orderId, this.order});

  final int orderId;

  /// Passed straight from Checkout; otherwise loaded
  final Order? order;

  @override
  ConsumerState<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends ConsumerState<OrderPlacedScreen> with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final _utr = TextEditingController();
  Timer? _ask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _pop.value = 1;
      } else {
        _pop.forward();
        HapticFeedback.heavyImpact();
      }
      // first order: ask once whether we may send order updates (after the celebration settles)
      _ask = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) ref.read(pushProvider.notifier).askOnce();
      });
    });
  }

  @override
  void dispose() {
    _ask?.cancel();
    _pop.dispose();
    _utr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final order = widget.order ?? ref.watch(orderProvider(widget.orderId)).value;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false, // Back goes Home, never back into Checkout
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/');
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [IconButton(tooltip: l.close, onPressed: () => context.go('/'), icon: const Icon(Icons.close_rounded))],
          ),
          body: order == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
                  Center(
                    child: ScaleTransition(
                      scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: NmColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: NmColors.success.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(l.orderPlaced, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall!.copyWith(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(order.awaitingPayment ? l.orderPlacedPay : l.orderPlacedThanks,
                      textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 10),
                  Center(child: _CopyChip(label: l.orderNumber(order.number), value: order.number, copied: l.orderIdCopied)),
                  if (order.awaitingPayment) ...[
                    const SizedBox(height: 16),
                    UpiPanel(order: order, utr: _utr),
                  ],
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/account/orders/${order.id}'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(l.viewOrder),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(l.continueShopping, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),
                ]),
        ),
      ),
    );
  }
}

/// "₹850" or "₹850.50" (paise only when there are some, like the website)
String _amount(double v) => v % 1 == 0 ? rupees(v) : priceExact(v);

class UpiPanel extends StatelessWidget {
  const UpiPanel({super.key, required this.order, required this.utr});

  final Order order;
  final TextEditingController utr;

  /// upi://pay link: opens Google Pay / PhonePe / Paytm / BHIM with the amount and order filled in
  Uri get _upiLink => Uri(scheme: 'upi', host: 'pay', queryParameters: {
        'pa': AppConfig.upiId,
        'pn': AppConfig.upiPayee,
        'am': order.total.toStringAsFixed(2),
        'cu': 'INR',
        'tn': 'Order ${order.number}',
      });

  Future<void> _payWithApp(BuildContext context) async {
    final l = AppLocalizations.of(context);
    var opened = false;
    try {
      opened = await launchUrl(_upiLink, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && context.mounted) showNmSnack(context, l.noUpiApp);
  }

  Future<void> _saveQr(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      if (!await Gal.hasPermission()) await Gal.requestPermission();
      final bytes = (await rootBundle.load(AppConfig.upiQrAsset)).buffer.asUint8List();
      await Gal.putImageBytes(bytes, name: 'NirmalMart-UPI-QR');
      if (context.mounted) showNmSnack(context, l.qrSaved);
    } catch (_) {
      if (context.mounted) showNmSnack(context, l.qrNotSaved);
    }
  }

  void _sendProof(BuildContext context) {
    final ref = utr.text.trim();
    final message = [
      'Hello Nirmal Mart, I have paid for my order.',
      'Order ID: ${order.number}',
      'Amount: ${_amount(order.total)}',
      if (order.customerName != null) 'Name: ${order.customerName}',
      if (ref.isNotEmpty) 'UPI reference (UTR): $ref',
      'Payment screenshot attached.',
    ].join('\n');
    openWhatsApp(context, AppConfig.paymentWhatsApp, message);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final amount = _amount(order.total);
    Widget action(IconData icon, String label, VoidCallback onTap, {bool primary = false}) {
      // icon + label that shrinks to fit narrow phones
      final content = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1))),
      ]);
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(42)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
      );
      return SizedBox(
        height: 42,
        child: primary
            ? FilledButton(onPressed: onTap, style: style, child: content)
            : OutlinedButton(onPressed: onTap, style: style, child: content),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.paymentPending.toUpperCase(),
            style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
        Text(l.payByUpi2(amount), style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            image: true,
            label: l.qrFor(AppConfig.upiPayee),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 118,
                decoration: BoxDecoration(border: Border.all(color: dark ? NmColors.darkLine : const Color(0xFFEDEDE7)), borderRadius: BorderRadius.circular(14)),
                child: Image.asset(AppConfig.upiQrAsset, fit: BoxFit.fitWidth),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              action(Icons.account_balance_wallet_outlined, l.payWithUpiApp, () => _payWithApp(context), primary: true),
              const SizedBox(height: 7),
              action(Icons.download_rounded, l.saveQr, () => _saveQr(context)),
              const SizedBox(height: 7),
              action(Icons.copy_rounded, l.copyUpiId, () async {
                await Clipboard.setData(const ClipboardData(text: AppConfig.upiId));
                if (context.mounted) showNmSnack(context, l.upiIdCopied);
              }),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(text: 'UPI ID: ', children: [TextSpan(text: AppConfig.upiId, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700))]),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(l.payStepsTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        const SizedBox(height: 4),
        for (final (i, s) in [l.payStep1(amount), l.payStep2, l.payStep3].indexed)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 18, child: Text('${i + 1}.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 13))),
              Expanded(child: Text(s, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.85), fontSize: 13, height: 1.4))),
            ]),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: utr,
          maxLength: 40,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l.utrHint, counterText: '', prefixIcon: const Icon(Icons.receipt_long_outlined)),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => _sendProof(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF128C4B),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.chat_rounded),
          label: Text(l.sendProof),
        ),
        const SizedBox(height: 6),
        Text(l.sendProofNote(AppConfig.paymentWhatsAppDisplay), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
      ]),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.label, required this.value, required this.copied});

  final String label;
  final String value;
  final String copied;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF22252B) : NmColors.muted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) showNmSnack(context, copied);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
