import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/net_image.dart';

/// Big swipeable photo at the top of the product page, with thumbnails and a "1 / 3" counter.
/// Tapping a photo opens it full screen with pinch-to-zoom.
class ProductGallery extends StatefulWidget {
  const ProductGallery({super.key, required this.images, required this.height, this.photoKey});

  final List<String> images;
  final double height;

  /// Marks the photo, so "add to bag" can fly a copy of it to the bag icon
  final GlobalKey? photoKey;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _openViewer() async {
    final back = await Navigator.of(context).push<int>(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => PhotoViewer(images: widget.images, initial: _index),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
    if (back != null && back != _index && mounted) _pages.jumpToPage(back);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final images = widget.images.isEmpty ? <String?>[null] : widget.images;
    final n = images.length;
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: n,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Semantics(
              image: true,
              button: images[i] != null,
              label: l.photoOf(i + 1, n),
              child: GestureDetector(
                onTap: images[i] == null ? null : _openViewer,
                child: KeyedSubtree(
                  key: i == _index ? widget.photoKey : null,
                  child: NetImage(images[i], width: 1200),
                ),
              ),
            ),
          ),
          // soft shade at the top so the round buttons stand out on light photos
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x47000000), Color(0x00000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ),
          ),
          if (n > 1) ...[
            Positioned(
              left: 16,
              bottom: 46,
              child: Row(
                children: [
                  for (var i = 0; i < n && i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Semantics(
                        button: true,
                        selected: i == _index,
                        label: l.photoOf(i + 1, n),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => _go(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: i == _index ? NmColors.brand : Colors.white.withValues(alpha: 0.85), width: 2),
                              boxShadow: [if (i == _index) const BoxShadow(color: Colors.white, spreadRadius: 2)],
                            ),
                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(images[i], width: 120)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 52,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0x99111217), borderRadius: BorderRadius.circular(99)),
                child: Text('${_index + 1} / $n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen photos on black: swipe between them, pinch or double-tap to zoom
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  final _zoom = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final z = _zoom.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) setState(() => _zoomed = z);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = widget.images.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              physics: _zoomed ? const NeverScrollableScrollPhysics() : null, // pan the photo, not the pages
              itemCount: n,
              onPageChanged: (i) {
                _zoom.value = Matrix4.identity();
                setState(() => _index = i);
              },
              itemBuilder: (context, i) => GestureDetector(
                onDoubleTap: () => _zoom.value = _zoomed ? Matrix4.identity() : (Matrix4.identity()..scaleByDouble(2.2, 2.2, 1, 1)),
                child: InteractiveViewer(
                  transformationController: i == _index ? _zoom : null,
                  minScale: 1,
                  maxScale: 4,
                  child: Center(child: NetImage(widget.images[i], width: 1200, fit: BoxFit.contain)),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l.close,
                      onPressed: () => Navigator.of(context).pop(_index),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    if (n > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('${_index + 1} / $n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
