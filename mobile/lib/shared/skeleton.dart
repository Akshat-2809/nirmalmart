import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmering grey shapes shown while content loads (design: 1.2 s sweep). Holds still when the
/// phone asks for reduced motion.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF25282E) : const Color(0xFFEEEEEA);
    final hi = dark ? const Color(0xFF30333A) : const Color(0xFFF8F8F5);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      period: const Duration(milliseconds: 1200),
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: child,
    );
  }
}

/// One grey block inside a [Skeleton]
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8, this.circle = false});

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      );
}
