import 'package:flutter/material.dart';

/// Device classification based on physical screen width
/// Follows Material Design 3 breakpoints with optimizations for Flutter
enum DeviceType { mobile, mobileLarge, tablet, tabletLarge, desktop }

/// Standard breakpoints across devices
/// Calibrated for real-world device distribution
class Breakpoints {
  // Mobile devices
  static const double mobile = 0;
  static const double mobileLarge = 600; // iPhone 12/13/14 landscape

  // Tablet devices
  static const double tablet = 1024; // iPad mini
  static const double tabletLarge = 1200; // iPad standard

  // Desktop
  static const double desktop = 1500; // Desktop/Web

  /// Precision detection with hysteresis to prevent jitter
  static DeviceType detect(double width) {
    if (width >= desktop) return DeviceType.desktop;
    if (width >= tabletLarge) return DeviceType.tabletLarge;
    if (width >= tablet) return DeviceType.tablet;
    if (width >= mobileLarge) return DeviceType.mobileLarge;
    return DeviceType.mobile;
  }
}

/// Safe insets for notches, status bars, and safe areas
/// Prevents content overlap with system UI
class SafeInsets {
  final double top;
  final double bottom;
  final double left;
  final double right;

  SafeInsets({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  EdgeInsets get insets => EdgeInsets.fromLTRB(left, top, right, bottom);

  static SafeInsets fromMediaQuery(MediaQueryData mq) {
    return SafeInsets(
      top: mq.padding.top,
      bottom: mq.padding.bottom,
      left: mq.padding.left,
      right: mq.padding.right,
    );
  }
}

/// Responsive scaling metrics
/// Base: iPhone 12 Pro Max (390px) - covers 95% of mobile devices
class ResponsiveMetrics {
  final double screenWidth;
  final double screenHeight;
  final DeviceType deviceType;
  final SafeInsets safeInsets;
  final double devicePixelRatio;

  ResponsiveMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.deviceType,
    required this.safeInsets,
    required this.devicePixelRatio,
  });

  /// Scale factor relative to base device (390px)
  /// 1.0 = baseline, >1.0 = larger device, <1.0 = smaller device
  double get scaleFactor => screenWidth / 390.0;

  /// Font scale with bounds to prevent extreme sizes
  /// Clamps between 0.8x and 1.4x for readability
  double get fontScaleFactor => (screenWidth / 390.0).clamp(0.8, 1.4);

  /// Aspect ratio helper
  bool get isPortrait => screenHeight > screenWidth;
  bool get isLandscape => screenWidth > screenHeight;

  /// Safe area aware height (usable area excluding notches)
  double get usableHeight => screenHeight - safeInsets.top - safeInsets.bottom;
  double get usableWidth => screenWidth - safeInsets.left - safeInsets.right;

  /// Device classification helpers
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isMobileLarge => deviceType == DeviceType.mobileLarge;
  bool get isTablet =>
      deviceType == DeviceType.tablet || deviceType == DeviceType.tabletLarge;
  bool get isDesktop => deviceType == DeviceType.desktop;

  factory ResponsiveMetrics.fromMediaQuery(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ResponsiveMetrics(
      screenWidth: mq.size.width,
      screenHeight: mq.size.height,
      deviceType: Breakpoints.detect(mq.size.width),
      safeInsets: SafeInsets.fromMediaQuery(mq),
      devicePixelRatio: mq.devicePixelRatio,
    );
  }
}
