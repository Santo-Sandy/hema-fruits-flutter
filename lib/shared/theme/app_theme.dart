import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Cashew Marketplace Material 3 ThemeData
///
/// Color roles:
///  • Brown  = primary  → buttons, CTAs, active states, progress
///  • Olive  = secondary → AppBar, navigation, tabs, hero sections
///  • Gold   = accent   → premium badges, verified, featured
///  • Cream  = neutral  → backgrounds, surfaces
class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: LightColorScheme.scheme,
    scaffoldBackgroundColor: AppColors.background, // Beige
    fontFamily: 'Poppins',

    // ── AppBar — OLIVE GREEN header ──
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navBg, // Olive Green
      foregroundColor: AppColors.navText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: AppColors.navText,
      ),
      iconTheme: IconThemeData(color: AppColors.navText),
      actionsIconTheme: IconThemeData(color: AppColors.navText),
      surfaceTintColor: Colors.transparent,
    ),

    // ── FilledButton — LIGHT BROWN CTA ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.button, // Light Brown
        foregroundColor: AppColors.buttonText,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        elevation: 0,
      ),
    ),

    // ── ElevatedButton — LIGHT BROWN CTA ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.button, // Light Brown
        foregroundColor: AppColors.buttonText,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        elevation: 2,
      ),
    ),

    // ── OutlinedButton — LIGHT BROWN border ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.buttonOutlineText, // Light Brown
        side: BorderSide(color: AppColors.buttonOutlineBorder, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    // ── TextButton — OLIVE GREEN ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary, // Olive Green
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // ── FAB — LIGHT BROWN CTA ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.button, // Light Brown
      foregroundColor: AppColors.buttonText,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── Input Decoration — Olive Green focus ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.inputFocusedBorder,
          width: 2,
        ), // Olive Green
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: TextStyle(
        color: AppColors.textHint,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      errorStyle: TextStyle(
        color: AppColors.error,
        fontSize: 12,
        fontFamily: 'Poppins',
      ),
      prefixIconColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? AppColors.primary
            : AppColors.textSecondary,
      ),
      suffixIconColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? AppColors.primary
            : AppColors.textSecondary,
      ),
    ),

    // ── Cards — White, rounded 20, beige border ──
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // ── Chips — Olive Green selected ──
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySoft, // subtle olive bg
      selectedColor: AppColors.primary, // Olive Green
      labelStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamily: 'Poppins',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ── Bottom Navigation — Beige bg, Olive Green active ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.footerBg, // Beige
      selectedItemColor: AppColors.navSelected, // Olive Green
      unselectedItemColor: AppColors.navInactiveIcon,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11),
    ),

    // ── NavigationBar — Beige bg, Olive Green active ──
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.footerBg, // Beige
      indicatorColor: AppColors.navIndicator, // Subtle olive pill
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors
                    .navSelected // Olive Green
              : AppColors.navInactiveIcon,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Poppins',
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.normal,
          color: s.contains(WidgetState.selected)
              ? AppColors
                    .navSelected // Olive Green
              : AppColors.navInactiveIcon,
          fontSize: 11,
        ),
      ),
    ),

    // ── Tabs — OLIVE GREEN bar, GOLD indicator ──
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.tabIndicator, // Gold
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14),
    ),

    // ── Progress Indicator — OLIVE GREEN ──
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primary, // Olive Green
      linearTrackColor: AppColors.primarySoft,
      circularTrackColor: AppColors.primarySoft,
    ),

    // ── Checkbox — OLIVE GREEN selected ──
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surface,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: AppColors.borderLight, width: 1.5),
    ),

    // ── Switch — OLIVE GREEN selected ──
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.disabled,
      ),
      trackColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primarySoft
            : AppColors.borderLight,
      ),
    ),

    // ── Radio — OLIVE GREEN ──
    radioTheme: RadioThemeData(
      fillColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.borderLight,
      ),
    ),

    // ── Slider — OLIVE GREEN ──
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primarySoft,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimaryLight,
      contentTextStyle: TextStyle(
        color: AppColors.surface,
        fontFamily: 'Poppins',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textPrimaryLight,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textSecondaryLight,
      ),
    ),

    // ── Bottom Sheet ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── Drawer — OLIVE GREEN header ──
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.surface,
      scrimColor: AppColors.overlay.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
    ),

    // ── ListTile ──
    listTileTheme: ListTileThemeData(
      textColor: AppColors.textPrimaryLight,
      iconColor: AppColors.textSecondaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // ── Divider ──
    dividerTheme: DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 16,
    ),

    // ── Icon Theme ──
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight, size: 24),
    primaryIconTheme: IconThemeData(color: AppColors.navText, size: 24),

    // ── Ripple — Olive Green ──
    splashFactory: InkRipple.splashFactory,
    highlightColor: AppColors.primary.withValues(alpha: 0.08),
    splashColor: AppColors.primary.withValues(alpha: 0.10),

    // ── Text Theme — warm dark brown tones ──
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        fontSize: 36,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 32,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 28,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontSize: 26,
      ), // Olive Green headings
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontSize: 22,
      ), // Olive Green headings
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        fontSize: 18,
      ), // Olive Green headings
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 17,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textTertiary,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        fontSize: 10,
      ),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: DarkColorScheme.scheme,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
  );
}
