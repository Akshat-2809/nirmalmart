import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/catalog/recent_and_pincode.dart';
import '../../core/orders/orders.dart';
import '../../core/theme/tokens.dart';
import '../../core/validate.dart';
import '../../l10n/app_localizations.dart';

/// States and union territories (same list as the website's AddressForm)
const indianStates = [
  'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chandigarh', 'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
  'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
];

/// New address form in a sheet. Saves it to the account and returns it (null if closed).
Future<Address?> showAddressSheet(BuildContext context, {bool firstAddress = false, Address? existing, bool fromCheckout = true}) => showModalBottomSheet<Address>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressSheet(firstAddress: firstAddress, existing: existing, fromCheckout: fromCheckout),
    );

class _AddressSheet extends ConsumerStatefulWidget {
  const _AddressSheet({required this.firstAddress, this.existing, this.fromCheckout = true});

  /// Checkout says "Save and deliver here"; Account just "Save address"
  final bool fromCheckout;

  final bool firstAddress;

  /// Editing this saved address (null = a new one)
  final Address? existing;

  @override
  ConsumerState<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<_AddressSheet> {
  final _form = GlobalKey<FormState>();
  late final _user = ref.read(authProvider).value;
  late final _old = widget.existing;
  late final _name = TextEditingController(text: _old?.fullName ?? _user?.fullName ?? '');
  late final _phone = TextEditingController(text: Validate.cleanMobile(_old?.phone ?? _user?.phone ?? ''));
  late final _pin = TextEditingController(text: _old?.pincode ?? ref.read(pincodeProvider) ?? '');
  late final _line1 = TextEditingController(text: _old?.line1 ?? '');
  late final _line2 = TextEditingController(text: _old?.line2 ?? '');
  late final _city = TextEditingController(text: _old?.city ?? '');
  late String? _state = indianStates.contains(_old?.state) ? _old!.state : 'Maharashtra'; // mostly Maharashtra
  late String _label = const {'Home', 'Work', 'Other'}.contains(_old?.label) ? _old!.label : 'Home';
  bool _busy = false;
  bool _tried = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _pin, _line1, _line2, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final input = AddressInput(
            label: _label,
            fullName: _name.text,
            phone: _phone.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            state: _state!,
            pincode: _pin.text,
            isDefault: widget.firstAddress || (_old?.isDefault ?? false),
          );
      final notifier = ref.read(addressesProvider.notifier);
      final a = _old == null ? await notifier.add(input) : await notifier.edit(_old.id, input);
      await ref.read(pincodeProvider.notifier).set(a.pincode); // delivery dates follow this address
      if (mounted) Navigator.of(context).pop(a);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget gap() => const SizedBox(height: 12);
    TextInputFormatter clean(String Function(String) f) => TextInputFormatter.withFunction((o, n) {
          final v = f(n.text);
          return v == n.text ? n : TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
        });

    final labels = [('Home', '🏠', l.labelHome), ('Work', '💼', l.labelWork), ('Other', '📍', l.labelOther)];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          autovalidateMode: _tried ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_old == null ? l.newAddress : l.editAddress, style: t.headlineSmall!.copyWith(fontSize: 20)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l.fieldFullName, prefixIcon: const Icon(Icons.person_outline_rounded)),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                inputFormatters: [clean(Validate.cleanName)],
                validator: (v) => Validate.isName(v ?? '') ? null : l.errName,
              ),
              gap(),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: l.fieldMobile, prefixIcon: const Icon(Icons.phone_outlined), prefixText: '+91 '),
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                textInputAction: TextInputAction.next,
                inputFormatters: [clean(Validate.cleanMobile)],
                validator: (v) => Validate.isMobile(v ?? '') ? null : l.errMobile,
              ),
              gap(),
              TextFormField(
                controller: _pin,
                decoration: InputDecoration(labelText: l.pincodeField, prefixIcon: const Icon(Icons.location_on_outlined)),
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
                textInputAction: TextInputAction.next,
                inputFormatters: [clean(Validate.cleanPincode)],
                validator: (v) => Validate.isPincode(v ?? '') ? null : l.pincodeInvalid,
              ),
              gap(),
              TextFormField(
                controller: _line1,
                decoration: InputDecoration(labelText: l.fieldLine1, prefixIcon: const Icon(Icons.home_outlined)),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.streetAddressLine1],
                textInputAction: TextInputAction.next,
                maxLength: 255,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                validator: (v) => (v ?? '').trim().length >= 3 ? null : l.errLine1,
              ),
              gap(),
              TextFormField(
                controller: _line2,
                decoration: InputDecoration(labelText: l.fieldLine2, prefixIcon: const Icon(Icons.signpost_outlined)),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.streetAddressLine2],
                textInputAction: TextInputAction.next,
              ),
              gap(),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    decoration: InputDecoration(labelText: l.fieldCity),
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.addressCity],
                    inputFormatters: [clean(Validate.cleanCity)],
                    validator: (v) => Validate.isCity(v ?? '') ? null : l.errCity,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _state,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.fieldState),
                    items: [for (final s in indianStates) DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _state = v),
                    validator: (v) => v == null ? l.errState : null,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Wrap(spacing: 8, children: [
                for (final (value, emoji, label) in labels)
                  ChoiceChip(
                    label: Text('$emoji $label'),
                    selected: _label == value,
                    onSelected: (_) => setState(() => _label = value),
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: NmColors.deal, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(_old != null ? l.saveChanges : widget.fromCheckout ? l.saveDeliverHere : l.saveAddress),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
