import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Fades a child in while sliding it up by [distance] px, starting [delayMs] into [controller]'s run.
/// One controller drives a whole screen's staggered entrance (design: 550 ms each, staggered).
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.controller, required this.delayMs, required this.child, this.distance = 16});

  final AnimationController controller;
  final int delayMs;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = controller.duration!.inMilliseconds;
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(math.min(1, delayMs / total), math.min(1, (delayMs + 550) / total), curve: NmMotion.entranceCurve),
    );
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.translate(offset: Offset(0, distance * (1 - anim.value)), child: child),
        child: child,
      ),
    );
  }
}
