import 'package:flutter/widgets.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle get titleMedium =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge => const TextStyle(fontSize: 14);

  static TextStyle get bodyMedium => const TextStyle(fontSize: 12);

  static TextStyle get labelMedium =>
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle responsive(
    BuildContext context, {
    required double baseSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) {
      return TextStyle(fontSize: desktopSize ?? (tabletSize ?? baseSize));
    }
    if (width >= 768) {
      return TextStyle(fontSize: tabletSize ?? baseSize);
    }
    return TextStyle(fontSize: baseSize);
  }
}
