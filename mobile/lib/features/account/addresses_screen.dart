import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/product_card.dart' show showNmSnack;
import '../checkout/address_sheet.dart';

/// Saved addresses: add, edit, delete, set the default (used first at checkout)
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final q = ref.watch(addressesProvider);
    final list = q.value;
    final scheme = Theme.of(context).colorScheme;

    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        if (context.mounted) showNmSnack(context, done);
      } catch (e) {
        if (context.mounted) showNmSnack(context, errorMessage(e));
      }
    }

    final Widget body;
    if (list == null) {
      body = q.hasError
          ? Center(child: TextButton(onPressed: () => ref.invalidate(addressesProvider), child: Text(l.tryAgain)))
          : const Center(child: CircularProgressIndicator());
    } else if (list.isEmpty) {
      body = ListView(padding: const EdgeInsets.fromLTRB(32, 72, 32, 32), children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.location_on_outlined, size: 44, color: scheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.noAddressesYet, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text(l.noAddressesBody, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
      ]);
    } else {
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        for (final a in list)
          _AddressTile(
            address: a,
            onEdit: () => showAddressSheet(context, existing: a, fromCheckout: false),
            onDefault: a.isDefault ? null : () => run(() => ref.read(addressesProvider.notifier).makeDefault(a), l.defaultSet),
            onDelete: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(l.deleteAddressQ),
                  content: Text(a.oneLine),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
                    TextButton(onPressed: () => Navigator.of(c).pop(true), style: TextButton.styleFrom(foregroundColor: NmColors.deal), child: Text(l.remove)),
                  ],
                ),
              );
              if (ok == true) await run(() => ref.read(addressesProvider.notifier).remove(a.id), l.addressDeleted);
            },
          ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.savedAddresses), backgroundColor: scheme.surface),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-address',
        onPressed: () => showAddressSheet(context, firstAddress: list?.isEmpty ?? true, fromCheckout: false),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l.addNewAddress),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.onEdit, required this.onDelete, this.onDefault});

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDefault;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = address;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: a.isDefault ? scheme.primary : (dark ? NmColors.darkLine : const Color(0xFFEDEDE7)), width: a.isDefault ? 1.6 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          _Chip(text: a.label.toUpperCase()),
          if (a.isDefault) _Chip(text: l.defaultTag, color: scheme.primary),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text('${a.oneLine}\n${a.phone}', style: TextStyle(fontSize: 13, height: 1.45, color: scheme.onSurface.withValues(alpha: 0.8))),
        ),
        Row(children: [
          if (onDefault != null) TextButton(onPressed: onDefault, child: Text(l.makeDefault)),
          const Spacer(),
          IconButton(tooltip: l.edit, onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
          IconButton(tooltip: l.remove, onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: NmColors.deal)),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12) ?? (dark ? const Color(0xFF22252B) : NmColors.muted),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
