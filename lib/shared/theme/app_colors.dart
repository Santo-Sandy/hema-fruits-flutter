import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════════
//
//  HEMA FRUITS — PRODUCTION COLOR SYSTEM
//
//  Brand Identity (from logo):
//   GREEN  (#5B6F1D)  = Brand / Agriculture / Growth          45% of UI
//   BROWN  (#6A3512)  = Actions / Commerce / Trust            10% of UI
//   GOLD   (#D9A441)  = Premium / Verified / Featured          5% of UI
//   CREAM  (#F8F5EF)  = Backgrounds / Warm surfaces           15% of UI
//   WHITE  (#FFFFFF)  = Cards / Surfaces / Content            25% of UI
//
//  Sections:
//   1.  PRIMARY BRAND        — Olive/Agriculture Green (#5B6F1D)
//   2.  SECONDARY            — Cashew Brown (#6A3512)
//   3.  PREMIUM GOLD         — (#D9A441)
//   4.  BACKGROUND
//   5.  SURFACE
//   6.  TEXT
//   7.  BORDER
//   8.  STATUS               — Success, Warning, Error, Info
//   9.  MARKETPLACE SPECIFIC — Stock, Requirement, Featured, Verified
//   10. BUTTON GRADIENTS     — Primary (Brown), Secondary (Green), Premium (Gold)
//   11. DASHBOARD GRADIENTS  — Hero, Analytics, Premium
//   12. NAVIGATION
//   13. INPUT FIELDS
//   14. SHADOW
//   15. BACKWARD-COMPAT ALIASES (mapped to new tokens — DO NOT REMOVE)
//
// ═════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static Color _hex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static List<Color> _hexList(List<dynamic> list) =>
      list.map((e) => _hex(e as String)).toList();
  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  1. PRIMARY BRAND — Agriculture Green
  //
  //     AppBar, hero sections, navigation active state, section headers,
  //     market stats, analytics, progress indicators, brand elements
  //
  // ═══════════════════════════════════════════════════════════════════════════
  static Color appheader = Color(0xFF1E5E42);
  static Color appheadertext = Color(0xFFFFFFFF);

  static Color primary = Color(0xFF1E5E42); // Forest Green
  static Color primaryDark = Color(0xFF0F3A27);
  static Color primaryLight = Color(0xFF2E8B57);
  static Color primarySoft = Color(0xFFE8F5E9); // Mint green bg

  // static const Color primary = Color(0xFF6A3512);
  // static const Color primaryDark = Color(0xFF4A240B);
  // static const Color primaryLight = Color(0xFF8C5A3C);
  // static const Color primarySoft = Color(0xFFF1E5DD);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  2. SECONDARY — Cashew Brown (Commerce / Actions)
  //
  //     ★ TO RESTYLE ALL BUTTONS — CHANGE ONLY THIS SECTION ★
  //
  //     Primary CTA buttons, Login, Register, OTP, Buy, Sell,
  //     Contact Seller, Submit, Save, FABs
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color secondary = Color(0xFFE65100); // Tangerine Orange
  static Color secondaryDark = Color(0xFFBF360C);
  static Color secondaryLight = Color(0xFFFF7043);
  static Color secondarySoft = Color(0xFFFBE9E7); // Peach bg

  // static Color secondary = Color(0xFF6A3512);
  // static Color secondaryDark = Color(0xFF4A240B);
  // static Color secondaryLight = Color(0xFF8C5A3C);
  // static Color secondarySoft = Color(0xFFF1E5DD); // subtle brown bg

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  3. PREMIUM GOLD — Verified / Featured / Premium (use sparingly — 5%)
  //
  //     Verified seller badges, Featured listings, Premium membership,
  //     Achievement badges, important KPIs
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color gold = Color(0xFFFFB300); // Gold
  static Color goldDark = Color(0xFFFF8F00);
  static Color goldLight = Color(0xFFFFD54F);
  static Color goldSoft = Color(0xFFFFF8E1); // Light gold bg

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  4. BACKGROUND — Warm cream tones
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color background = Color(0xFFF8F9FA); // Clean off-white bg
  static Color backgroundSecondary = Color(0xFFF1F3F4);
  static Color backgroundTertiary = Color(0xFFE8EAED);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  5. SURFACE
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color activebottom = Color(0xFF1E5E42); // Active bottom tab indicator
  static Color surface = Color(0xFFFFFFFF);
  static Color surfaceVariant = Color(0xFFF8F9FA);

  // Dark mode surfaces
  static Color surfaceDark = Color(0xFF1C1410);
  static Color surfaceContainerDark = Color(0xFF2A1E16);
  static Color surfaceVariantDark = Color(0xFF352618);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  6. TEXT
  //
  // ═══════════════════════════════════════════════════════════════════════════

  // Light theme
  static Color textPrimary = Color(0xFF1F1F1F);
  static Color textSecondary = Color(0xFF555555);
  static Color textTertiary = Color(0xFF7A7A7A);
  static Color textHint = Color(0xFFA3A3A3);

  // On-color text (always white on brand colors)
  static Color textOnPrimary = Color(0xFFFFFFFF);
  static Color textOnSecondary = Color(0xFFFFFFFF);
  static Color textOnGold = Color(0xFFFFFFFF);

  // Dark theme text
  static Color textPrimaryDark = Color(0xFFF5EAD8);
  static Color textSecondaryDark = Color(0xFFD4B898);
  static Color textTertiaryDark = Color(0xFFA08060);
  static Color textHintDark = Color(0xFF5C4030);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  7. BORDER
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color border = Color(0xFFE0E0E0);
  static Color borderLight = Color(0xFFEEEEEE);
  static Color borderDark = Color(0xFFBDBDBD);
  static Color borderLighter = Color(0xFFF5F5F5);
  static Color borderDarker = Color(0xFF9E9E9E);
  static Color divider = Color(0xFFE0E0E0);

  // Dark mode borders
  static Color borderDarkMode = Color(0xFF3D2A1A);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  8. STATUS COLORS
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color success = Color(0xFF4E7A22);
  static Color successLight = Color(0xFFE8F5DC);

  static Color warning = Color(0xFFC48A1D);
  static Color warningLight = Color(0xFFFFF2D8);

  static Color error = Color(0xFFB4442C);
  static Color errorLight = Color(0xFFFDE6E2);

  static Color info = Color(0xFF3F6C8F);
  static Color infoLight = Color(0xFFE5F0F8);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  9. MARKETPLACE SPECIFIC
  //
  //     Use these for consistent semantic coloring across all listing cards
  //
  // ═══════════════════════════════════════════════════════════════════════════

  // — Stock Listings (available = green) —
  static Color stockAvailable = Color(0xFF2E7D32);
  static Color stockAvailableBg = Color(0xFFE8F5E9);

  // — Requirements (orange = commerce action) —
  static Color requirement = Color(0xFFE65100);
  static Color requirementBg = Color(0xFFFBE9E7);

  // — Featured (gold) —
  static Color featured = Color(0xFFFFB300);
  static Color featuredBg = Color(0xFFFFF8E1);

  // — Verified (emerald = trust) —
  static Color verified = Color(0xFF2E7D32);
  static Color verifiedBg = Color(0xFFE8F5E9);

  // — Urgent / Expiring (red warning) —
  static Color urgent = Color(0xFFD84315);
  static Color urgentBg = Color(0xFFFFEBE7);

  // — Seller cards —
  static Color sellerCardBg = Color(0xFFE8F5E9); // Mint green bg
  static Color sellerCardBorder = Color(0xFFC8E6C9);
  static Color sellerCardAccent = Color(0xFF1E5E42);

  // — Buyer cards —
  static Color buyerCardBg = Color(0xFFFBE9E7); // Peach bg
  static Color buyerCardBorder = Color(0xFFFFCCBC);
  static Color buyerCardAccent = Color(0xFFE65100);

  // — Role colors —
  static Color buyerColor = Color(0xFFE65100); // Tangerine orange
  static Color merchantColor = Color(0xFF1E5E42); // Forest green
  static Color rcnColor = Color(0xFF2E8B57); // Fresh fruits accent
  static Color kernelColor = Color(0xFF8C6D31); // Dry fruits accent

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  10. BUTTON GRADIENTS
  //
  //     ★ TO CHANGE ALL PRIMARY BUTTONS — UPDATE primaryButtonGradient ★
  //
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary CTA — Orange gradient (Login, Buy, Sell, Submit, Save, FAB)
  static LinearGradient primaryButtonGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF7043)],
  );

  /// Secondary CTA — Green gradient (secondary actions)
  static LinearGradient secondaryButtonGradient = LinearGradient(
    colors: [Color(0xFF1E5E42), Color(0xFF2E8B57)],
  );

  /// Premium CTA — Gold gradient (upgrade, featured, premium)
  static LinearGradient premiumButtonGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
  );

  // Flat button colors (for non-gradient use)
  static Color button = Color(0xFFE65100); // Tangerine CTA
  static Color buttonDark = Color(0xFFBF360C);
  static Color buttonLight = Color(0xFFFF7043);
  static Color buttonText = Color(0xFFFFFFFF);
  static Color buttonOutlineBorder = Color(0xFFE65100);
  static Color buttonOutlineText = Color(0xFFE65100);
  static Color buttonDisabled = Color(0xFFE0E0E0);
  static Color buttonDisabledText = Color(0xFF9E9E9E);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  11. DASHBOARD GRADIENTS
  //
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hero banner — dark-to-medium green
  static LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3A27), Color(0xFF1E5E42)],
  );

  /// Market analytics cards
  static LinearGradient analyticsGradient = LinearGradient(
    colors: [Color(0xFF1E5E42), Color(0xFF2E8B57)],
  );

  /// Premium membership banner
  static LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
  );

  /// Header/AppBar gradient
  static LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3A27), Color(0xFF1E5E42)],
  );

  /// Background fade (green → cream)
  static LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E5E42), Color(0xFFF8F9FA)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  12. NAVIGATION
  //
  //     ★ TO RESTYLE ALL NAVIGATION — CHANGE ONLY THIS SECTION ★
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color navBackground = Color(0xFFFFFFFF); // Footer/bottom nav bg
  static Color navSelected = Color(0xFF1E5E42); // Active — Green
  static Color navUnselected = Color(0xFF8E8E8E); // Inactive
  static Color navIndicator = Color(0xFFE8F5E9); // Active item bg pill

  // AppBar specific
  static Color navBg = Color(0xFF1E5E42); // Green AppBar
  static Color navBgDark = Color(0xFF0F3A27); // Darker green on scroll
  static Color navText = Color(0xFFFFFFFF); // White text on nav
  static Color navActiveIcon = Color(0xFF1E5E42); // Active bottom nav icon
  static Color navInactiveIcon = Color(0xFF8E8E8E);

  // Header
  static Color headerBg = Color(0xFF1E5E42);
  static Color footerBg = Color(0xFFFFFFFF);
  static Color sectionHeader = Color(0xFF1E5E42);
  static Color tabIndicator = Color(0xFFFFB300); // Gold tab indicator

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  13. INPUT FIELDS
  //
  //     ★ TO RESTYLE ALL INPUTS — CHANGE ONLY THIS SECTION ★
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color inputBackground = Color(0xFFF5F7F8);
  static Color inputBorder = Color(0xFFE0E0E0);
  static Color inputFocusedBorder = Color(0xFF1E5E42); // Green focus
  static Color inputErrorBorder = Color(0xFFD84315);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  14. SHADOW
  //
  // ═══════════════════════════════════════════════════════════════════════════

  static Color shadowLight = Color.fromRGBO(0, 0, 0, 0.04);
  static Color shadowMedium = Color.fromRGBO(0, 0, 0, 0.08);
  static Color shadowStrong = Color.fromRGBO(0, 0, 0, 0.12);

  // Legacy shadow aliases
  static Color shadowLighter = Color.fromRGBO(0, 0, 0, 0.04);
  static Color shadowDark = Color.fromRGBO(0, 0, 0, 0.40);
  static Color shadowDarker = Color.fromRGBO(0, 0, 0, 0.60);

  static Color overlay = Color(0xFF000000);

  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  15. BACKWARD-COMPAT ALIASES
  //
  //     These map legacy variable names → new tokens.
  //     DO NOT REMOVE — used throughout 475+ files.
  //
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary aliases (→ Green)
  static Color primaryDarkAlias = Color(0xFF0F3A27);
  static Color primaryLightAlias = Color(0xFF2E8B57);
  static Color primarySubtle = Color(0xFFE8F5E9);

  // Secondary aliases (→ Orange)
  static Color secondaryDarkAlias = Color(0xFFBF360C);
  static Color secondaryLightAlias = Color(0xFFFF7043);
  static Color secondarySubtle = Color(0xFFFBE9E7);

  // Accent (→ Gold)
  static Color accent = Color(0xFFE65100);
  static Color accentLight = Color(0xFFFF7043);
  static Color accentDark = Color(0xFFBF360C);
  static Color accentSubtle = Color(0xFFFBE9E7);

  // Background aliases
  static Color backgroundLight = Color(0xFFF8F9FA);
  static Color backgroundDark = Color(0xFFECE5D8);

  // Surface aliases
  static Color surfaceLight = Color(0xFFFFFFFF);
  static Color surfaceContainerLight = Color(0xFFF8F9FA);

  // Text aliases
  static Color textPrimaryLight = Color(0xFF1F1F1F);
  static Color textSecondaryLight = Color(0xFF555555);
  static Color textTertiaryLight = Color(0xFF7A7A7A);
  static Color textHintLight = Color(0xFFA3A3A3);

  // Border aliases
  static Color dividerAlias = Color(0xFFE0E0E0);

  // Semantic
  static Color disabled = Color(0xFFE0E0E0);

  // Card aliases
  static Color cardBg = Color(0xFFFFFFFF);
  static Color cardBorder = Color(0xFFEEEEEE);
  static Color cardShadow = Color.fromRGBO(0, 0, 0, 0.04);

  // Extended palette for widget use
  static Color olive = Color(0xFF1E5E42);
  static Color oliveLight = Color(0xFF2E8B57);
  static Color oliveDark = Color(0xFF0F3A27);
  static Color oliveSubtle = Color(0xFFE8F5E9);

  static Color brown = Color(0xFFE65100);
  static Color brownLight = Color(0xFFFF7043);
  static Color brownDark = Color(0xFFBF360C);
  static Color brownSubtle = Color(0xFFFBE9E7);

  static Color cream = Color(0xFFF8F9FA);
  static Color creamDark = Color(0xFFE8EAED);
  static Color creamLight = Color(0xFFFFFFFF);

  static Color beige = Color(0xFFE0E0E0);
  static Color beigeLight = Color(0xFFEEEEEE);
  static Color beigeDark = Color(0xFFBDBDBD);

  // Gradient backward-compat aliases
  static LinearGradient primaryGradient = headerGradient; // green hero
  static LinearGradient secondaryGradient =
      analyticsGradient; // green analytics
  static LinearGradient accentGradient = premiumGradient; // gold premium

  // Product type colors
  static Color RCN = Color(0xFF2E8B57); // Fresh fruits accent
  static Color Kernel = Color(0xFF8C6D31); // Dry fruits accent

  // Card-type accent maps (used by card widgets)
  static Color sellerCardText = Color(0xFF1F1F1F);
  static Color buyerCardText = Color(0xFF1F1F1F);
  static Color rcnCardBg = Color(0xFFE8F5E9); // Mint green bg
  static Color rcnCardBorder = Color(0xFFC8E6C9);
  static Color rcnCardAccent = Color(0xFF1E5E42);
  static Color rcnCardText = Color(0xFF0F3A27);
  static Color kernelCardBg = Color(0xFFFFF8E1); // Light yellow/orange bg
  static Color kernelCardBorder = Color(0xFFFFE082);
  static Color kernelCardAccent = Color(0xFFE65100);
  static Color kernelCardText = Color(0xFF5D4037);

  // ─────────────────────────────────────────────────────────────────────────
  // API UPDATE
  // ─────────────────────────────────────────────────────────────────────────

  static void updateFromApi(Map<String, dynamic> data) {
    // Primary
    final p = data['primary'] as Map<String, dynamic>;
    primary = _hex(p['main']);
    primaryDark = _hex(p['dark']);
    primaryLight = _hex(p['light']);
    primarySubtle = _hex(p['subtle']);
    // appheader = _hex(p['appheader']);
    // Accent / secondary
    accent = _hex(data['accent']);
    secondary = _hex(data['secondary']);

    // Product-type brand
    final custom = data['custom'] as Map<String, dynamic>;
    Kernel = _hex(custom['kernel']);
    RCN = _hex(custom['rcn']);

    // Background
    final bg = data['background'] as Map<String, dynamic>;
    backgroundDark = _hex(bg['dark']);
    backgroundLight = _hex(bg['light']);
    background = backgroundLight;

    // Surface
    final sf = data['surface'] as Map<String, dynamic>;
    surfaceDark = _hex(sf['dark']);
    surfaceLight = _hex(sf['light']);
    surfaceContainerDark = _hex(sf['containerDark']);
    surfaceContainerLight = _hex(sf['containerLight']);
    surface = surfaceLight;

    // Text
    final txt = data['text'] as Map<String, dynamic>;
    final tl = txt['light'] as Map<String, dynamic>;
    textPrimaryLight = _hex(tl['primary']);
    textSecondaryLight = _hex(tl['secondary']);
    textTertiaryLight = _hex(tl['tertiary']);
    textHintLight = _hex(tl['hint']);

    final td = txt['dark'] as Map<String, dynamic>;
    textPrimaryDark = _hex(td['primary']);
    textSecondaryDark = _hex(td['secondary']);
    textTertiaryDark = _hex(td['tertiary']);
    textHintDark = _hex(td['hint']);

    // Legacy aliases
    textPrimary = textPrimaryLight;
    textSecondary = textSecondaryLight;
    textHint = textHintLight;

    // Border
    final bd = data['border'] as Map<String, dynamic>;
    borderDark = _hex(bd['dark']);
    borderDarker = _hex(bd['darker']);
    borderLight = _hex(bd['light']);
    borderLighter = _hex(bd['lighter']);
    divider = borderLight;

    // Neutrals
    final nt = data['neutral'] as Map<String, dynamic>;
    background = _hex(nt['background']);
    surface = _hex(nt['surface']);
    divider = _hex(nt['divider']);

    // Status
    final st = data['status'] as Map<String, dynamic>;
    success = _hex(st['success']);
    error = _hex(st['error']);
    warning = _hex(st['warning']);
    info = _hex(st['info']);

    // Role colours
    final role = data['role'] as Map<String, dynamic>;
    buyerColor = _hex(role['buyer']);
    kernelColor = _hex(role['kernel']);
    merchantColor = _hex(role['merchant']);
    rcnColor = _hex(role['rcn']);

    // Card colours (optional — only if API provides them)
    if (data['card'] != null) {
      final card = data['card'] as Map<String, dynamic>;
      if (card['seller'] != null) {
        final s = card['seller'] as Map<String, dynamic>;
        sellerCardBg = _hex(s['bg']);
        sellerCardBorder = _hex(s['border']);
        sellerCardAccent = _hex(s['accent']);
        sellerCardText = _hex(s['text']);
      }
      if (card['buyer'] != null) {
        final b = card['buyer'] as Map<String, dynamic>;
        buyerCardBg = _hex(b['bg']);
        buyerCardBorder = _hex(b['border']);
        buyerCardAccent = _hex(b['accent']);
        buyerCardText = _hex(b['text']);
      }
      if (card['rcn'] != null) {
        final r = card['rcn'] as Map<String, dynamic>;
        rcnCardBg = _hex(r['bg']);
        rcnCardBorder = _hex(r['border']);
        rcnCardAccent = _hex(r['accent']);
        rcnCardText = _hex(r['text']);
      }
      if (card['kernel'] != null) {
        final k = card['kernel'] as Map<String, dynamic>;
        kernelCardBg = _hex(k['bg']);
        kernelCardBorder = _hex(k['border']);
        kernelCardAccent = _hex(k['accent']);
        kernelCardText = _hex(k['text']);
      }
    }

    // Layout
    final layout = data['layout'] as Map<String, dynamic>;
    headerBg = _hex(layout['header']);
    footerBg = _hex(layout['footer']);

    // Semantic
    final sem = data['semantic'] as Map<String, dynamic>;
    disabled = _hex(sem['disabled']);
    overlay = _hex(sem['overlay']);

    // Shadow
    final sh = data['shadow'] as Map<String, dynamic>;
    shadowLight = _hex(sh['light']);
    shadowDark = _hex(sh['dark']);
    shadowLighter = _hex(sh['lighter']);
    shadowDarker = _hex(sh['darker']);

    // Gradient
    final gr = data['gradient'] as Map<String, dynamic>;
    primaryGradient = LinearGradient(colors: _hexList(gr['primary']));
    backgroundGradient = LinearGradient(colors: _hexList(gr['background']));

    // Rebuild colour schemes
    LightColorScheme.scheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySubtle,
      onPrimaryContainer: textPrimaryLight,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surfaceLight,
      onSurface: textPrimaryLight,
      error: error,
      onError: Colors.white,
    );

    DarkColorScheme.scheme = ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.black,
      primaryContainer: primaryDark,
      onPrimaryContainer: textPrimaryDark,
      secondary: secondary,
      onSecondary: Colors.black,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
      error: error,
      onError: Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL COLOR SCHEMES
// ─────────────────────────────────────────────────────────────────────────────

class LightColorScheme {
  static ColorScheme scheme = ColorScheme.light(
    primary: AppColors.primary, // Agriculture Green
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.secondary, // Cashew Brown
    onSecondary: AppColors.textOnSecondary,
    secondaryContainer: AppColors.secondarySoft,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.gold, // Premium Gold
    onTertiary: AppColors.textOnGold,
    tertiaryContainer: AppColors.goldSoft,
    onTertiaryContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLow: AppColors.background,
    surfaceContainerHighest: AppColors.backgroundTertiary,
    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.error,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
    shadow: AppColors.shadowLight,
  );
}

class DarkColorScheme {
  static ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.primaryLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.textPrimaryDark,
    secondary: AppColors.secondaryLight,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.textPrimaryDark,
    tertiary: AppColors.goldLight,
    onTertiary: Color(0xFF1F1F1F),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    outline: AppColors.borderDarkMode,
    outlineVariant: Color(0xFF4A3020),
  );
}
