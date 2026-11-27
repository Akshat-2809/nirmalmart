import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cart/cart.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';

/// "Add ₹150 more for FREE delivery" with a progress bar, above the bottom tabs while the bag has
/// something in it but is under the free-delivery amount.
class FreeDeliveryBar extends ConsumerWidget {
  const FreeDeliveryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider).value ?? Cart.empty;
    final need = AppConfig.freeDeliveryThreshold - cart.subtotal;
    final show = cart.count > 0 && need > 0;
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: still ? const Duration(milliseconds: 1) : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: show ? _Bar(need: need, progress: cart.subtotal / AppConfig.freeDeliveryThreshold) : const SizedBox(width: double.infinity),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.need, required this.progress});

  final double need;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final amount = rupees(need.ceil());
    final text = l.freeDeliveryMore(amount);
    final at = text.indexOf(amount);
    final still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Material(
        color: scheme.surface,
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/bag'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.local_shipping_outlined, size: 19, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      at < 0
                          ? TextSpan(text: text)
                          : TextSpan(children: [
                              TextSpan(text: text.substring(0, at)),
                              TextSpan(text: amount, style: const TextStyle(fontWeight: FontWeight.w800)),
                              TextSpan(text: text.substring(at + amount.length)),
                            ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(l.viewBag, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  Icon(Icons.chevron_right_rounded, size: 18, color: scheme.primary),
                ]),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress.clamp(0.0, 1.0)),
                  duration: still ? Duration.zero : const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(NmColors.success),
                    ),
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
