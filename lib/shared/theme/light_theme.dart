import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Cashew Marketplace Light Theme
///
/// Color roles (production):
///  • Green  (#5B6F1D) = brand, AppBar, nav, progress, focus — 45%
///  • Brown  (#6A3512) = buttons, CTAs, FABs                 — 10%
///  • Gold   (#D9A441) = premium, verified, tab indicator    — 5%
///  • Cream  (#F8F5EF) = backgrounds                        — 15%
///  • White  (#FFFFFF) = cards, surfaces                    — 25%
class LightTheme {
  LightTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: LightColorScheme.scheme,
      fontFamily: AppTextThemes.fontFamily,
      textTheme: AppTextThemes.getLightTextTheme,
      scaffoldBackgroundColor: AppColors.background, // Beige
      // ── AppBar — OLIVE GREEN brand header ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navBg, // Olive Green
        foregroundColor: AppColors.navText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextThemes.getLightTextTheme.titleLarge?.copyWith(
          color: AppColors.navText,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.navText),
        actionsIconTheme: IconThemeData(color: AppColors.navText),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Cards — White, radius 16, warm border ──
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shadowColor: AppColors.shadowMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // ── FilledButton — LIGHT BROWN CTA ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.button, // Light Brown
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.getLightTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonDisabledText,
        ),
      ),

      // ── OutlinedButton — LIGHT BROWN border ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonOutlineText, // Light Brown
          side: BorderSide(color: AppColors.buttonOutlineBorder, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.getLightTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── TextButton — OLIVE GREEN ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary, // Olive Green
          textStyle: AppTextThemes.getLightTextTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── ElevatedButton — LIGHT BROWN CTA ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button, // Light Brown
          foregroundColor: AppColors.buttonText,
          elevation: 2,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.getLightTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: AppColors.shadowMedium,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonDisabledText,
        ),
      ),

      // ── Input fields — Olive Green focus, beige bg ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputFocusedBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputErrorBorder, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputErrorBorder, width: 2),
        ),
        hintStyle: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
          color: AppColors.textHint,
        ),
        labelStyle: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? AppColors.primary
              : AppColors.textTertiary,
        ),
        suffixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? AppColors.primary
              : AppColors.textTertiary,
        ),
      ),

      // ── Checkbox — OLIVE GREEN ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),

      // ── Switch — OLIVE GREEN ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textTertiary,
        ),
        trackColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.borderLight,
        ),
        trackOutlineColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
      ),

      // ── Radio — OLIVE GREEN ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
      ),

      // ── Slider — OLIVE GREEN ──
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primarySoft,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x146B7A2A),
      ),

      // ── ProgressIndicator — OLIVE GREEN ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
        circularTrackColor: AppColors.primarySoft,
        linearMinHeight: 4,
      ),

      // ── FAB — LIGHT BROWN CTA ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.button, // Light Brown
        foregroundColor: AppColors.buttonText,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Chips — OLIVE GREEN selected ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary, // Olive Green
        disabledColor: AppColors.buttonDisabled,
        labelStyle: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: AppColors.borderLight, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Bottom Nav — OLIVE GREEN active, BEIGE bg ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.footerBg, // Beige
        selectedItemColor: AppColors.navSelected, // Olive Green
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextThemes.getLightTextTheme.labelSmall,
      ),

      // ── NavigationBar (Material 3) — OLIVE GREEN active, BEIGE bg ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.footerBg, // Beige
        indicatorColor: AppColors.navIndicator, // Subtle olive pill
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors
                      .navSelected // Olive Green
                : AppColors.navUnselected,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: AppTextThemes.fontFamily,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
            color: s.contains(WidgetState.selected)
                ? AppColors
                      .navSelected // Olive Green
                : AppColors.navUnselected,
            fontSize: 11,
          ),
        ),
        elevation: 0,
      ),

      // ── Tabs — GREEN bar, GOLD indicator ──
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.tabIndicator,
        labelStyle: AppTextThemes.getLightTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextThemes.getLightTextTheme.labelLarge,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.shadowStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextThemes.getLightTextTheme.headlineSmall,
        contentTextStyle: AppTextThemes.getLightTextTheme.bodyMedium,
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),

      // ── Drawer ──
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surface,
        scrimColor: Colors.black.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),

      // ── List Tile ──
      listTileTheme: ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 16,
      ),

      // ── Icon Theme ──
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      primaryIconTheme: IconThemeData(color: AppColors.navText, size: 24),

      // ── Ripple — OLIVE GREEN ──
      splashFactory: InkRipple.splashFactory,
      highlightColor: const Color(0x146B7A2A),
      splashColor: const Color(0x1E6B7A2A),
    );
  }
}
