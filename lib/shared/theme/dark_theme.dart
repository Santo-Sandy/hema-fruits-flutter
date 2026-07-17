import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Cashew Marketplace Dark Theme
class DarkTheme {
  DarkTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: DarkColorScheme.scheme,
      fontFamily: AppTextThemes.fontFamily,
      textTheme: AppTextThemes.darkTextTheme,
      scaffoldBackgroundColor: AppColors.surfaceDark,

      // ── AppBar — DARK GREEN ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navBgDark,
        foregroundColor: AppColors.navText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextThemes.darkTextTheme.titleLarge?.copyWith(
          color: AppColors.navText,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.navText),
        actionsIconTheme: IconThemeData(color: AppColors.navText),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerDark,
        shadowColor: AppColors.shadowStrong,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
      ),

      // ── FilledButton — BROWN CTA ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.button,
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.darkTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonDisabledText,
        ),
      ),

      // ── OutlinedButton — BROWN border ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonOutlineText,
          side: BorderSide(color: AppColors.buttonOutlineBorder, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.darkTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── TextButton — lighter GREEN for dark bg ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTextThemes.darkTextTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── ElevatedButton — BROWN CTA ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button,
          foregroundColor: AppColors.buttonText,
          elevation: 2,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextThemes.darkTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonDisabledText,
        ),
      ),

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextThemes.darkTextTheme.bodyMedium?.copyWith(
          color: AppColors.textHintDark,
        ),
        labelStyle: AppTextThemes.darkTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        floatingLabelStyle: AppTextThemes.darkTextTheme.bodySmall?.copyWith(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTextThemes.darkTextTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? AppColors.primaryLight
              : AppColors.textTertiaryDark,
        ),
        suffixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? AppColors.primaryLight
              : AppColors.textTertiaryDark,
        ),
      ),

      // ── Checkbox — lighter GREEN ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.surfaceContainerDark,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: AppColors.borderDarkMode, width: 1.5),
      ),

      // ── Switch — lighter GREEN ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.textTertiaryDark,
        ),
        trackColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.borderDarkMode,
        ),
      ),

      // ── Radio ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.textTertiaryDark,
        ),
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryLight,
        inactiveTrackColor: AppColors.primaryDark,
        thumbColor: AppColors.primaryLight,
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.12),
      ),

      // ── Progress ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.primaryDark,
        linearMinHeight: 4,
      ),

      // ── FAB — BROWN CTA ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.button,
        foregroundColor: AppColors.buttonText,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Chips — GREEN selected ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.buttonDisabled.withValues(alpha: 0.3),
        labelStyle: AppTextThemes.darkTextTheme.labelMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: AppColors.borderDarkMode, width: 1),
      ),

      // ── Bottom Nav — OLIVE active ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        unselectedLabelStyle: AppTextThemes.darkTextTheme.labelSmall,
      ),

      // ── Tabs — GOLD indicator ──
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: AppColors.tabIndicator,
        labelStyle: AppTextThemes.darkTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextThemes.darkTextTheme.labelLarge,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerDark,
        contentTextStyle: AppTextThemes.darkTextTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextThemes.darkTextTheme.headlineSmall,
        contentTextStyle: AppTextThemes.darkTextTheme.bodyMedium,
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.borderDarkMode,
      ),

      // ── List Tile ──
      listTileTheme: ListTileThemeData(
        textColor: AppColors.textPrimaryDark,
        iconColor: AppColors.textSecondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: AppColors.borderDarkMode,
        thickness: 1,
        space: 16,
      ),

      // ── Icon Theme ──
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 24),
      primaryIconTheme: IconThemeData(color: AppColors.navText, size: 24),

      // ── Ripple ──
      splashFactory: InkRipple.splashFactory,
      highlightColor: const Color(0x147C9440),
      splashColor: const Color(0x1E7C9440),
    );
  }
}
