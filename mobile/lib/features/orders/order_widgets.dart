import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Colour and words for an order's state, as the customer should read it
({String label, Color fg, Color bg}) orderBadge(AppLocalizations l, Order o, {required bool dark}) {
  ({String label, Color fg, Color bg}) b(String label, Color fg, Color light, Color darkBg) => (label: label, fg: fg, bg: dark ? darkBg : light);
  const amber = Color(0xFF92400E), blue = Color(0xFF1D4ED8), green = NmColors.success, grey = NmColors.inkSoft;
  if (o.cancelled) {
    if (o.paymentStatus == 'refunded') return b(l.stRefunded, green, const Color(0xFFDCFCE7), const Color(0xFF173323));
    if (o.paymentStatus == 'refund_pending') return b(l.stRefundPending, amber, const Color(0xFFFEF3C7), const Color(0xFF3A2F17));
    return b(l.stCancelled, dark ? const Color(0xFFB8BBC4) : grey, NmColors.muted, const Color(0xFF22252B));
  }
  if (o.awaitingPayment) return b(l.stAwaitingPayment, amber, const Color(0xFFFEF3C7), const Color(0xFF3A2F17));
  if (o.hasOpenReturn) return b(l.stReturnInProgress, amber, const Color(0xFFFEF3C7), const Color(0xFF3A2F17));
  return switch (o.status) {
    'shipped' => b(l.stShipped, dark ? const Color(0xFF93B4F5) : blue, const Color(0xFFE0ECFB), const Color(0xFF1C2838)),
    'delivered' => b(l.stDelivered, green, const Color(0xFFDCFCE7), const Color(0xFF173323)),
    'processing' => b(l.stPacked, dark ? NmColors.brandOnDark : NmColors.brand, NmColors.brandSoft, NmColors.brandDark),
    _ => b(l.stConfirmed, dark ? NmColors.brandOnDark : NmColors.brand, NmColors.brandSoft, NmColors.brandDark),
  };
}

class OrderBadge extends StatelessWidget {
  const OrderBadge({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final b = orderBadge(AppLocalizations.of(context), order, dark: Theme.of(context).brightness == Brightness.dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: b.bg, borderRadius: BorderRadius.circular(99)),
      child: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: b.fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}

String shortDate(BuildContext context, DateTime d) => DateFormat('d MMM', Localizations.localeOf(context).toString()).format(d);
String dayDate(BuildContext context, DateTime d) => DateFormat('EEE, d MMM', Localizations.localeOf(context).toString()).format(d);

/// "Today, 9:17 PM" / "21 Nov"
String placedWhen(BuildContext context, DateTime d) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return '${l.today}, ${DateFormat.jm(Localizations.localeOf(context).toString()).format(d)}';
  }
  return DateFormat(d.year == now.year ? 'd MMM' : 'd MMM y', Localizations.localeOf(context).toString()).format(d);
}

/// Placed → Confirmed → Packed → Shipped → Delivered
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = [l.stepPlaced, l.stepConfirmed, l.stepPacked, l.stepShipped, l.stepDelivered];
    final at = Order.steps.indexOf(status).clamp(0, 4);
    final idle = dark ? NmColors.darkLine : NmColors.line;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: labels[at],
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / labels.length;
        return SizedBox(
          height: 52,
          child: Stack(children: [
            Positioned(left: w / 2, right: w / 2, top: 10, child: Container(height: 3, color: idle)),
            Positioned(
              left: w / 2,
              top: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? at.toDouble() : 0, end: at.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Container(height: 3, width: w * v, color: scheme.primary),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                SizedBox(
                  width: w,
                  child: Column(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < at || (i == at && i == labels.length - 1) ? scheme.primary : scheme.surface,
                        border: Border.all(color: i <= at ? scheme.primary : idle, width: i == at ? 3 : 2),
                      ),
                      child: i < at || (i == at && i == labels.length - 1) ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 5),
                    Text(labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i <= at ? scheme.onSurface : scheme.onSurfaceVariant)),
                  ]),
                ),
            ]),
          ]),
        );
      }),
    );
  }
}

/// A white rounded card with an optional small caps title
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, this.title, required this.child, this.color, this.border});

  final String? title;
  final Widget child;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? (dark ? NmColors.darkLine : const Color(0xFFEDEDE7))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: scheme.onSurfaceVariant)),
          ),
        child,
      ]),
    );
  }
}
