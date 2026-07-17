import 'package:flutter/material.dart';
import 'responsive_config.dart';

extension ResponsiveContext on BuildContext {
  /// Get cached responsive metrics (optimized for performance)
  ResponsiveMetrics get responsive {
    return ResponsiveMetrics.fromMediaQuery(this);
  }

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get usableHeight => responsive.usableHeight;
  double get usableWidth => responsive.usableWidth;

  DeviceType get deviceType => responsive.deviceType;
  bool get isMobile => responsive.isMobile;
  bool get isMobileLarge => responsive.isMobileLarge;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;

  bool get isPortrait => responsive.isPortrait;
  bool get isLandscape => responsive.isLandscape;

  // ==================== Scaling Factors ====================

  double get scaleFactor => responsive.scaleFactor;
  double get fontScaleFactor => responsive.fontScaleFactor;
  double get dpScaleFactor => responsive.devicePixelRatio;

  // ==================== Spacing Helpers (Responsive) ====================

  /// Responsive horizontal spacing
  /// Base: 16px on 390px device, scales proportionally
  double h(double baseValue) {
    final scaled = baseValue * scaleFactor;
    // Clamp to prevent extreme values
    return scaled.clamp(4.0, 200.0);
  }

  /// Responsive vertical spacing
  double v(double baseValue) {
    final scaled = baseValue * scaleFactor;
    return scaled.clamp(4.0, 200.0);
  }

  /// Responsive radius
  double r(double baseValue) {
    final scaled = baseValue * scaleFactor;
    return scaled.clamp(2.0, 50.0);
  }

  // ==================== Common Spacings ====================

  double get spacing4 => h(4);
  double get spacing8 => h(8);
  double get spacing12 => h(12);
  double get spacing16 => h(16);
  double get spacing20 => h(20);
  double get spacing24 => h(24);
  double get spacing32 => h(32);

  // ==================== Padding & Insets ====================

  EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: h(12), vertical: v(10));

  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: h(6));
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: v(16));

  EdgeInsets get smallPadding => EdgeInsets.all(h(8));
  EdgeInsets get mediumPadding => EdgeInsets.all(h(16));
  EdgeInsets get largePadding => EdgeInsets.all(h(24));

  /// Safe area padding with notch awareness
  EdgeInsets get safePadding {
    final safe = responsive.safeInsets;
    return EdgeInsets.fromLTRB(
      safe.left + h(16),
      safe.top + v(12),
      safe.right + h(16),
      safe.bottom + v(12),
    );
  }

  // ==================== Typography Sizes ====================

  double get fontSizeXSmall => 10 * fontScaleFactor;
  double get fontSizeSmall => 12 * fontScaleFactor;
  double get fontSizeBase => 14 * fontScaleFactor;
  double get fontSizeMedium => 16 * fontScaleFactor;
  double get fontSizeLarge => 18 * fontScaleFactor;
  double get fontSizeXLarge => 20 * fontScaleFactor;
  double get fontSizeXXLarge => 24 * fontScaleFactor;
  double get fontSizeHeading => 32 * fontScaleFactor;

  // ==================== Icon Sizes ====================

  double get iconSizeXSmall => 12 * fontScaleFactor;
  double get iconSizeSmall => 16 * fontScaleFactor;
  double get iconSizeMedium => 20 * fontScaleFactor;
  double get iconSizeLarge => 24 * fontScaleFactor;
  double get iconSizeXLarge => 32 * fontScaleFactor;

  // ==================== Component Heights ====================

  double get appBarHeight {
    if (isTablet) return v(72);
    if (isMobileLarge) return v(64);
    return v(56);
  }

  double get bottomNavHeight {
    if (isTablet) return v(90);
    return v(70);
  }

  double get buttonHeight {
    if (isTablet) return v(56);
    return v(48);
  }

  double get textFieldHeight {
    if (isTablet) return v(56);
    return v(48);
  }

  double get cardMinHeight => isTablet ? v(180) : v(160);

  // ==================== Grid & Layout ====================

  /// Columns for grid/list layouts
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    if (isMobileLarge) return 2;
    return 1;
  }

  /// Responsive grid spacing
  double get gridSpacing {
    if (isTablet) return h(16);
    return h(12);
  }

  /// Cross-axis max extent for grids
  double get gridChildMaxWidth {
    if (isDesktop) return usableWidth / 4;
    if (isTablet) return usableWidth / 3;
    if (isMobileLarge) return usableWidth / 2;
    return usableWidth;
  }

  double get gridChildAspectRatio {
    if (isPortrait) return 2.0;
    if (isLandscape) return 1.4;
    return 1.8;
  }

  // ==================== Radius ====================

  double get radiusSmall => r(6);
  double get radiusMedium => r(12);
  double get radiusLarge => r(16);
  double get radiusXLarge => r(24);

  // ==================== Shadows ====================

  BoxShadow get shadowSmall => BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  BoxShadow get shadowMedium => BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  BoxShadow get shadowLarge => BoxShadow(
    color: Colors.black.withValues(alpha: 0.15),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );

  // ==================== Responsive Conditionals ====================

  /// Show widget only on specific device types
  /// Usage: context.show(isMobile, widget)
  Widget? show(bool condition, Widget widget) {
    return condition ? widget : null;
  }

  /// Switch between widgets based on device type
  /// Usage: context.switchDevice(
  ///   mobile: mobileBuild,
  ///   tablet: tabletBuild,
  ///   desktop: desktopBuild,
  /// )
  Widget switchDevice({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop) return desktop ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Conditional value based on device
  T switchValue<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}

/// Short aliases for common responsive methods
extension ResponsiveShortcuts on BuildContext {
  // Spacing shortcuts
  SizedBox gap(double space) => SizedBox(height: v(space), width: h(space));
  SizedBox hGap(double space) => SizedBox(width: h(space));
  SizedBox vGap(double space) => SizedBox(height: v(space));

  // Padding shortcuts
  Padding pad(Widget child) => Padding(padding: mediumPadding, child: child);
  Padding padH(Widget child) =>
      Padding(padding: horizontalPadding, child: child);
  Padding padV(Widget child) => Padding(padding: verticalPadding, child: child);
}
