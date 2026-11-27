import 'package:flutter/material.dart';

import '../../core/orders/orders.dart';
import '../checkout/order_placed_screen.dart';

/// "Pay now" on an unpaid order: the same UPI panel as right after checkout, in a sheet
Future<void> showPaySheet(BuildContext context, Order order) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the bottom tabs
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PaySheet(order: order),
    );

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.order});

  final Order order;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  final _utr = TextEditingController();

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: UpiPanel(order: widget.order, utr: _utr),
        ),
      );
}
