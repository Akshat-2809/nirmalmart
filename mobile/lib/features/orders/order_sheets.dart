import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';
import '../../shared/product_card.dart';

// Reasons as the website lists them. The English text is what the server (and the admin) sees;
// the Marathi is only shown.
const _cancelReasons = [
  ('Ordered by mistake', 'चुकून ऑर्डर केली'),
  ('Changed my mind', 'विचार बदलला'),
  ('Found a better price elsewhere', 'दुसरीकडे स्वस्त मिळाले'),
  ('Delivery is taking too long', 'डिलिव्हरीला खूप वेळ लागत आहे'),
  ('Need to change the address or items', 'पत्ता किंवा वस्तू बदलायच्या आहेत'),
  ('Other', 'इतर'),
];
const _returnReasons = [
  ('Item is damaged or defective', 'वस्तू खराब किंवा तुटलेली आहे'),
  ('Wrong item was sent', 'चुकीची वस्तू आली'),
  ('Parts or accessories missing', 'भाग किंवा अ‍ॅक्सेसरीज कमी आहेत'),
  ('Quality not as expected', 'दर्जा अपेक्षेप्रमाणे नाही'),
  ('Item doesn’t match the description', 'वर्णनाप्रमाणे वस्तू नाही'),
  ('No longer needed', 'आता गरज नाही'),
];
const _exchangeReasons = [
  ('Item is damaged or defective', 'वस्तू खराब किंवा तुटलेली आहे'),
  ('Wrong size', 'चुकीचा आकार'),
  ('Wrong item was sent', 'चुकीची वस्तू आली'),
  ('Parts or accessories missing', 'भाग किंवा अ‍ॅक्सेसरीज कमी आहेत'),
];

String _shown(BuildContext context, (String, String) r) => Localizations.localeOf(context).languageCode == 'mr' ? r.$2 : r.$1;

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );

// ───────────── Cancel order ─────────────

Future<void> showCancelOrder(BuildContext context, WidgetRef ref, Order order) => _sheet(context, _CancelSheet(order: order));

class _CancelSheet extends ConsumerStatefulWidget {
  const _CancelSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends ConsumerState<_CancelSheet> {
  (String, String)? _reason;
  bool _busy = false;
  String? _error;

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await OrderActions(ref).cancel(widget.order.id, _reason?.$1);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNmSnack(context, l.orderCancelled);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.order;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.whyCancel, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          RadioGroup<(String, String)>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [
              for (final r in _cancelReasons)
                RadioListTile<(String, String)>(
                  value: r,
                  title: Text(_shown(context, r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ]),
          ),
          const SizedBox(height: 6),
          if (o.awb != null) _Note(text: l.cancelPackedNote),
          _Note(text: o.paymentStatus == 'paid' ? l.cancelRefundNote(rupees(o.total)) : l.cancelNoChargeNote),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: Text(l.keepOrder),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy || _reason == null ? null : _cancel,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: NmColors.deal),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(l.cancelOrder),
              ),
            ),
          ]),
          if (_reason == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.pickReason, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22252B) : NmColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85))),
      );
}

// ───────────── Return or exchange ─────────────

Future<void> showReturnSheet(BuildContext context, WidgetRef ref, Order order) => _sheet(context, _ReturnSheet(order: order));

class _ReturnSheet extends ConsumerStatefulWidget {
  const _ReturnSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends ConsumerState<_ReturnSheet> {
  String _kind = 'return';
  late final Map<int, int> _left = widget.order.returnableLines;
  // one line with one unit is picked to start with
  late final Map<int, int> _units = {for (final e in _left.entries) e.key: _left.length == 1 && e.value == 1 ? 1 : 0};
  (String, String)? _reason;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _anyChosen => _units.values.any((n) => n > 0);

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OrderActions(ref).requestReturn(
        widget.order.id,
        kind: _kind,
        items: {for (final e in _units.entries) if (e.value > 0) e.key: e.value},
        reason: _reason!.$1,
        comment: _comment.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showNmSnack(context, _kind == 'exchange' ? l.exchangeRequested : l.returnRequested);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reasons = _kind == 'exchange' ? _exchangeReasons : _returnReasons;
    final lines = widget.order.items.where((i) => _left.containsKey(i.id)).toList();
    final refund = lines.fold<double>(0, (s, i) => s + i.unitPrice * (_units[i.id] ?? 0));
    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.returnExchange, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'return', label: Text(l.returnForRefund), icon: const Icon(Icons.keyboard_return_rounded)),
              ButtonSegment(value: 'exchange', label: Text(l.exchangeIt), icon: const Icon(Icons.swap_horiz_rounded)),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() {
              _kind = v.first;
              if (!(_kind == 'exchange' ? _exchangeReasons : _returnReasons).contains(_reason)) _reason = null;
            }),
          ),
          heading(l.whichItems),
          for (final i in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Checkbox(
                  value: (_units[i.id] ?? 0) > 0,
                  onChanged: (v) => setState(() => _units[i.id] = v == true ? 1 : 0),
                ),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 44, height: 44, child: NetImage(i.image, width: 120))),
                const SizedBox(width: 10),
                Expanded(child: Text(i.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                if (_left[i.id]! > 1 && (_units[i.id] ?? 0) > 0)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: l.removeOne,
                      onPressed: (_units[i.id] ?? 0) > 1 ? () => setState(() => _units[i.id] = _units[i.id]! - 1) : null,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    Text('${_units[i.id]}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      tooltip: l.addOne,
                      onPressed: _units[i.id]! < _left[i.id]! ? () => setState(() => _units[i.id] = _units[i.id]! + 1) : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ]),
              ]),
            ),
          heading(l.whatsWrong),
          RadioGroup<(String, String)>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [
              for (final r in reasons)
                RadioListTile<(String, String)>(
                  value: r,
                  title: Text(_shown(context, r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ]),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.returnCommentHint, counterText: ''),
          ),
          const SizedBox(height: 6),
          _Note(text: _kind == 'exchange' ? l.exchangeNote : (refund > 0 ? l.returnNote(rupees(refund)) : l.returnNoteNoAmount)),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600))),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy || !_anyChosen || _reason == null ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(_kind == 'exchange' ? l.requestExchange : l.requestReturn),
          ),
          if (!_anyChosen || _reason == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.pickItemsAndReason, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }
}

// ───────────── Cancel a return request ─────────────

Future<void> confirmCancelReturn(BuildContext context, WidgetRef ref, Order order, ReturnRequest r) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(r.exchange ? l.cancelExchangeQ : l.cancelReturnQ),
      content: Text(l.cancelRequestBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.keepIt)),
        TextButton(onPressed: () => Navigator.of(c).pop(true), style: TextButton.styleFrom(foregroundColor: NmColors.deal), child: Text(l.cancelRequest)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await OrderActions(ref).cancelReturn(order.id, r.id);
    if (context.mounted) showNmSnack(context, l.requestCancelled);
  } catch (e) {
    if (context.mounted) showNmSnack(context, errorMessage(e));
  }
}

// ───────────── Rate items ─────────────

/// Delivered items, each opening its product page to write a review
Future<void> showRateSheet(BuildContext context, Order order) {
  final items = order.items.where((i) => i.slug != null).toList();
  if (items.length == 1) return context.push('/product/${items.first.slug}');
  return _sheet(
    context,
    Builder(builder: (context) {
      final l = AppLocalizations.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(l.rateItems, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
            ),
            for (final i in items)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 48, height: 48, child: NetImage(i.image, width: 120))),
                title: Text(i.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: const Icon(Icons.star_outline_rounded, color: NmColors.gold),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/product/${i.slug}');
                },
              ),
          ]),
        ),
      );
    }),
  );
}
