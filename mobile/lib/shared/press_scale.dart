import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Shrinks its child slightly while pressed (the design's "press" motion: scale 0.95, 150 ms).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.95});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !still ? widget.scale : 1,
        duration: NmMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
