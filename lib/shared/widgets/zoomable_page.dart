import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Wraps a page's content to make it pinch/drag zoomable.
class ZoomablePage extends StatelessWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomablePage({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      panEnabled: true,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: true,
      child: child,
    );
  }
}

class ZoomablePages extends StatelessWidget {
  final Widget child;

  const ZoomablePages({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PhotoView.customChild(
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      child: child,
    );
  }
}
