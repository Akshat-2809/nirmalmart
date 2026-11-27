import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/catalog/recent_and_pincode.dart';
import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';

/// Asks for a delivery pincode, checks it (same check as the website) and remembers it.
Future<void> showPincodeSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PincodeSheet(),
    );

class _PincodeSheet extends ConsumerStatefulWidget {
  const _PincodeSheet();

  @override
  ConsumerState<_PincodeSheet> createState() => _PincodeSheetState();
}

class _PincodeSheetState extends ConsumerState<_PincodeSheet> {
  late final _pin = TextEditingController(text: ref.read(pincodeProvider) ?? '');
  bool _busy = false;
  DeliveryCheck? _result;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final pin = _pin.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final r = await checkDelivery(ref.read(apiClientProvider), pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r;
    });
    if (r.date != null) await ref.read(pincodeProvider.notifier).set(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = _result;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.local_shipping_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l.pincodeTitle, style: t.headlineSmall!.copyWith(fontSize: 20))),
          ]),
          const SizedBox(height: 8),
          Text(l.pincodeBody, style: t.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _pin,
                  autofocus: _pin.text.isEmpty,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _check(),
                  decoration: InputDecoration(
                    labelText: l.pincodeField,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed: _busy ? null : _check,
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NmRadius.field))),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(l.pincodeCheck),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 1) : const Duration(milliseconds: 250),
            child: r == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(children: [
                      Icon(r.date != null ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          size: 20, color: r.date != null ? NmColors.success : NmColors.deal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.date != null ? l.pincodeDeliveryBy(r.date!) : (r.unserviceable ? l.pincodeUnserviceable : l.pincodeInvalid),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: r.date != null ? NmColors.success : NmColors.deal),
                        ),
                      ),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}

