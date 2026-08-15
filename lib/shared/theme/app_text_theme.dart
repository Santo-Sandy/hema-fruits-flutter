import 'package:flutter/material.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'app_colors.dart';

class AppTextThemes {
  AppTextThemes._();

  static const String fontFamily = 'Inter';

  // ==================== Base Font Sizes (Mobile Reference) ====================

  /// Display sizes - for large, prominent headlines
  static const double _displayLargeBase = 57;
  static const double _displayMediumBase = 45;
  static const double _displaySmallBase = 36;

  /// Headline sizes
  static const double _headlineLargeBase = 32;
  static const double _headlineMediumBase = 28;
  static const double _headlineSmallBase = 24;

  /// Title sizes
  static const double _titleLargeBase = 22;
  static const double _titleMediumBase = 18;
  static const double _titleSmallBase = 16;

  /// Body sizes
  static const double _bodyLargeBase = 16;
  static const double _bodyMediumBase = 14;
  static const double _bodySmallBase = 12;

  /// Label sizes
  static const double _labelLargeBase = 14;
  static const double _labelMediumBase = 12;
  static const double _labelSmallBase = 11;

  // ==================== Helper Methods for Responsive Sizing ====================

  /// Get responsive font size (normal scaling: 1.1x tablet, 1.25x desktop)
  static double _getResponsiveSize(BuildContext context, double baseSize) {
    return context.switchValue(
      mobile: baseSize,
      tablet: baseSize * 1.1,
      desktop: baseSize * 1.25,
    );
  }

  /// Get responsive display size (aggressive scaling: 1.15x tablet, 1.3x desktop)
  static double _getDisplaySize(BuildContext context, double baseSize) {
    return context.switchValue(
      mobile: baseSize,
      tablet: baseSize * 1.15,
      desktop: baseSize * 1.3,
    );
  }

  /// Get responsive headline size (moderate scaling: 1.12x tablet, 1.25x desktop)
  static double _getHeadlineSize(BuildContext context, double baseSize) {
    return context.switchValue(
      mobile: baseSize,
      tablet: baseSize * 1.12,
      desktop: baseSize * 1.25,
    );
  }

  // ==================== Light Theme ====================

  /// Get responsive light text theme
  ///
  /// Example:
  /// ```dart
  /// Text("Title", style: AppTextThemes.getgetLightTextTheme(context).headlineMedium)
  /// ```
  static TextTheme getgetLightTextTheme(BuildContext context) {
    return TextTheme(
      // Display sizes - for large, prominent headlines
      displayLarge: TextStyle(
        fontSize: _getDisplaySize(context, _displayLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: _getDisplaySize(context, _displayMediumBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: _getDisplaySize(context, _displaySmallBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),

      // Headline sizes
      headlineLarge: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineMediumBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.29,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineSmallBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),

      // Title sizes
      titleLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _titleLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.27,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _titleMediumBase),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.33,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: _getResponsiveSize(context, _titleSmallBase),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),

      // Body sizes
      bodyLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _bodyLargeBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _bodyMediumBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: AppColors.textSecondaryLight,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: _getResponsiveSize(context, _bodySmallBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textTertiaryLight,
        fontFamily: fontFamily,
      ),

      // Label sizes
      labelLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _labelLargeBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimaryLight,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _labelMediumBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: AppColors.textSecondaryLight,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: _getResponsiveSize(context, _labelSmallBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.textTertiaryLight,
        fontFamily: fontFamily,
      ),
    );
  }

  // ==================== Dark Theme ====================

  /// Get responsive dark text theme
  ///
  /// Example:
  /// ```dart
  /// Text("Title", style: AppTextThemes.getDarkTextTheme(context).headlineMedium)
  /// ```
  static TextTheme getDarkTextTheme(BuildContext context) {
    return TextTheme(
      // Display sizes
      displayLarge: TextStyle(
        fontSize: _getDisplaySize(context, _displayLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: _getDisplaySize(context, _displayMediumBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: _getDisplaySize(context, _displaySmallBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),

      // Headline sizes
      headlineLarge: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineMediumBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.29,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: _getHeadlineSize(context, _headlineSmallBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),

      // Title sizes
      titleLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _titleLargeBase),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.27,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _titleMediumBase),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.33,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: _getResponsiveSize(context, _titleSmallBase),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),

      // Body sizes
      bodyLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _bodyLargeBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _bodyMediumBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: AppColors.textSecondaryDark,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: _getResponsiveSize(context, _bodySmallBase),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textTertiaryDark,
        fontFamily: fontFamily,
      ),

      // Label sizes
      labelLarge: TextStyle(
        fontSize: _getResponsiveSize(context, _labelLargeBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimaryDark,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: _getResponsiveSize(context, _labelMediumBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: AppColors.textSecondaryDark,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: _getResponsiveSize(context, _labelSmallBase),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.textTertiaryDark,
        fontFamily: fontFamily,
      ),
    );
  }

  // ==================== Backward Compatibility (Static Fallback) ====================

  /// Light theme text theme (static, non-responsive)
  ///
  /// ⚠️ Deprecated: Use getgetLightTextTheme(context) for responsive sizing
  ///
  /// This is kept for backward compatibility only.
  /// Prefer the responsive version for all new code.
  @Deprecated('Use getgetLightTextTheme(context) for responsive sizing')
  static TextTheme getLightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.12,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.16,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.22,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.25,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.29,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.33,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.27,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.33,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.5,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      color: AppColors.textSecondaryLight,
      fontFamily: fontFamily,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
      color: AppColors.textTertiaryLight,
      fontFamily: fontFamily,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: AppColors.textPrimaryLight,
      fontFamily: fontFamily,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
      color: AppColors.textSecondaryLight,
      fontFamily: fontFamily,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
      color: AppColors.textTertiaryLight,
      fontFamily: fontFamily,
    ),
  );

  /// Dark theme text theme (static, non-responsive)
  ///
  /// ⚠️ Deprecated: Use getDarkTextTheme(context) for responsive sizing
  ///
  /// This is kept for backward compatibility only.
  /// Prefer the responsive version for all new code.
  @Deprecated('Use getDarkTextTheme(context) for responsive sizing')
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.12,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.16,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.22,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.25,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.29,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.33,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.27,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.33,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.5,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      color: AppColors.textSecondaryDark,
      fontFamily: fontFamily,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
      color: AppColors.textTertiaryDark,
      fontFamily: fontFamily,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: AppColors.textPrimaryDark,
      fontFamily: fontFamily,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
      color: AppColors.textSecondaryDark,
      fontFamily: fontFamily,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
      color: AppColors.textSecondaryDark,
      fontFamily: fontFamily,
    ),
  );
}
