import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stand-in for screens that aren't built yet. Delete once every route has its real screen.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(dark ? 'assets/images/logo-mark-dark.svg' : 'assets/images/logo-mark.svg', width: 140),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Coming soon', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
