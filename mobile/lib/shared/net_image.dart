import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/theme/tokens.dart';

/// Off in widget tests, which have no network or disk cache; the grey placeholder shows instead.
final networkImagesProvider = Provider<bool>((ref) => true);

/// Where photos come from: the phone's image cache, filled from the web. Previews swap in local files.
final imageSourceProvider = Provider<ImageProvider Function(String url)>((ref) => (url) => CachedNetworkImageProvider(url));

/// Clock-driven updates (countdowns, auto-sliding carousels, "still loading" hints).
/// Off in widget tests so pumpAndSettle can finish; a test can switch it on and pump() by hand.
final liveUpdatesProvider = Provider<bool>((ref) => true);

/// The image for [url] shown about [width] px wide: the thumbnail or full photo, decoded at that size.
/// Shared by [NetImage] and [prefetchPhoto] so a prefetched photo is the very one the page shows.
ImageProvider photoProvider(BuildContext context, WidgetRef ref, String url, int width) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return ResizeImage(
    ref.read(imageSourceProvider)(sized(url, width)),
    width: (width * dpr).round().clamp(64, 1400),
    policy: ResizeImagePolicy.fit,
  );
}

/// Starts downloading a photo before it's needed (e.g. as a product card is tapped)
void prefetchPhoto(BuildContext context, WidgetRef ref, String? url, {int width = 1200}) {
  if (url == null || url.isEmpty || !ref.read(networkImagesProvider)) return;
  precacheImage(photoProvider(context, ref, url, width), context, onError: (_, _) {});
}

/// A product or category photo: cached on the phone, a lighter copy for small slots, a soft fade-in.
/// While a big photo loads, its thumbnail (usually already on the phone from the product card) shows,
/// so there's no empty grey box; a grey tile with an icon only when there's nothing at all.
class NetImage extends ConsumerWidget {
  const NetImage(this.url, {super.key, this.width = 480, this.fit = BoxFit.cover, this.icon = Icons.shopping_bag_outlined});

  final String? url;

  /// Roughly how many pixels wide it shows at, to pick the thumbnail or the full photo
  final int width;
  final BoxFit fit;
  final IconData icon;

  /// The size product cards use: their copy is what shows while a big photo loads
  static const cardWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = ColoredBox(
      color: dark ? const Color(0xFF22252B) : NmColors.muted,
      child: Center(child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45))),
    );
    if (url == null || url!.isEmpty || !ref.watch(networkImagesProvider)) return grey;
    ref.watch(imageSourceProvider);
    final big = width > 600;
    final placeholder = big
        ? Image(
            image: photoProvider(context, ref, url!, cardWidth),
            fit: fit,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) => frame == null && !sync ? grey : child,
            errorBuilder: (_, _, _) => grey,
          )
        : grey;
    return Image(
      // decode at the size it's shown, so long lists stay light on memory
      image: photoProvider(context, ref, url!, width),
      fit: fit,
      gaplessPlayback: true,
      // placeholder until the photo is ready, then a soft fade-in (instant if it was already cached)
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : Stack(fit: StackFit.expand, children: [
              placeholder,
              AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 250), child: child),
            ]),
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
