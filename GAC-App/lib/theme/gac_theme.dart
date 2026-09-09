import 'package:flutter/material.dart';

/// Shared color tokens for Gateway Audit Compliance.
///
/// The app keeps its original mobile layouts and component geometry. These
/// tokens only carry the administrator dashboard palette across those screens.
abstract final class GacColors {
  // Blush canvas shared by the splash, login, and authenticated workspaces.
  static const blushLight = Color(0xFFFDF6F8);
  static const blushMiddle = Color(0xFFF9ECF0);
  static const blushPink = Color(0xFFF0BECC);
  static const blushPinkSoft = Color(0xFFF3C9D6);

  // Gateway dashboard brand colors.
  static const navy950 = Color(0xFF071E32);
  static const navy900 = Color(0xFF0B263D);
  static const navy800 = Color(0xFF153A56);
  static const navy700 = Color(0xFF244B67);
  static const brandRed = Color(0xFFE71D48);
  static const brandRedDark = Color(0xFFC9163B);
  static const brandRedSoft = Color(0xFFFDE8ED);

  // Cool dashboard neutrals.
  static const graphite = navy950;
  static const ink = navy900;
  static const steel = Color(0xFF5C6878);
  static const slate = Color(0xFF778292);
  static const stone = Color(0xFFA8B0BA);
  static const mist = Color(0xFFD2D8DF);
  static const fog = Color(0xFFF3F5F7);
  static const panelMuted = Color(0xFFF8F9FA);
  static const iconTile = Color(0xFFFFF2DE);

  // Supporting dashboard accents.
  static const blue = Color(0xFF2F65D9);
  static const cyan = Color(0xFF25A6B8);

  // Compliance green stays semantic: passed, complete, or compliant.
  static const green900 = Color(0xFF0B4E38);
  static const green800 = Color(0xFF126344);
  static const green600 = Color(0xFF249D6B);
  static const green400 = Color(0xFF47B889);
  static const green200 = Color(0xFF89D4B5);
  static const green100 = Color(0xFFBDE8D5);
  static const green50 = Color(0xFFEAF7F1);

  // Pending and review states.
  static const amber900 = Color(0xFF5A3505);
  static const amber800 = Color(0xFF784B08);
  static const amber600 = Color(0xFFA6670D);
  static const amber400 = Color(0xFFD49324);
  static const amber200 = Color(0xFFF0B957);
  static const amber100 = Color(0xFFF9D993);
  static const amber50 = Color(0xFFFFF4DE);

  // Gateway red doubles as the primary action and finding color.
  static const red900 = Color(0xFF7F102B);
  static const red800 = Color(0xFFA71333);
  static const red600 = brandRed;
  static const red400 = Color(0xFFF05270);
  static const red200 = Color(0xFFF49AAF);
  static const red100 = Color(0xFFF8C4D0);
  static const red50 = brandRedSoft;

  // Blue Brand Palette (Dark blue theme for buttons and active states).
  static const brandBlue = Color(0xFF2979FF);
  static const brandBlueDark = Color(0xFF1C68E3);
  static const brandBlueSoft = Color(0xFF102847);

  static const primary = brandBlue;
  static const primaryPressed = brandBlueDark;
  static const primaryContainer = brandBlueSoft;
  static const navigation = navy950;
  static const success = green600;
  static const successContainer = green50;
  static const warning = amber400;
  static const warningContainer = amber50;
  static const error = brandRed;
  static const errorContainer = brandRedSoft;

  // Dark Navy Theme Tokens.
  static const cardSurface = Color(0xFF0D1B2A);
  static const cardBorder = Color(0xFF1A3A5C);
  static const textPrimary = Color(0xFFE8EDF2);
  static const textSecondary = Color(0xFF8899AA);
  static const textMuted = Color(0xFF5C7A99);

  // Surface recipes mirrored from the splash badge and login card.
  static const glassSurface = Color(0xB30D1B2A);
  static const glassSurfaceStrong = Color(0xD90A1628);
  static const glassBorder = Color(0x331A5C8C);
  static const glassShadow = Color(0x40000000);
  static const panelBorder = Color(0xFF1A3A5C);
  static const panelShadow = Color(0x40000000);

  // Existing screen aliases adapted for dark navy theme.
  static const canvas = Color(0xFF0A1628);
  static const white = Color(0xFFFFFFFF);
  static const black = textPrimary;
  static const charcoal = Color(0xFF0D1B2A);
  static const gray = textSecondary;
  static const muted = textMuted;
  static const darkGray = textMuted;
  static const lightGray = Color(0xFF1A3A5C);
  static const border = Color(0xFF1A3A5C);
  static const offWhite = Color(0xFF0D2137);
}

abstract final class GacTheme {
  static const _colorScheme = ColorScheme.dark(
    primary: GacColors.primary,
    onPrimary: GacColors.white,
    primaryContainer: Color(0x2E2979FF),
    onPrimaryContainer: GacColors.textPrimary,
    secondary: GacColors.blue,
    onSecondary: GacColors.white,
    secondaryContainer: Color(0xFF102847),
    onSecondaryContainer: GacColors.textPrimary,
    tertiary: GacColors.green600,
    onTertiary: GacColors.white,
    tertiaryContainer: Color(0x26249D6B),
    onTertiaryContainer: GacColors.green200,
    surface: GacColors.cardSurface,
    onSurface: GacColors.textPrimary,
    error: GacColors.error,
    onError: GacColors.white,
    errorContainer: Color(0x2EE71D48),
    onErrorContainer: GacColors.red200,
    outline: GacColors.cardBorder,
    outlineVariant: Color(0xFF122A42),
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GacColors.canvas,
      colorScheme: _colorScheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: GacColors.cardBorder,
      disabledColor: GacColors.textMuted,
      iconTheme: const IconThemeData(color: GacColors.textPrimary),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: GacColors.cyan,
        selectionColor: Color(0x4400BCD4),
        selectionHandleColor: GacColors.cyan,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: GacColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: GacColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF0D2137),
        hintStyle: TextStyle(color: GacColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: GacColors.cardBorder),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: GacColors.cyan, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: GacColors.error),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: GacColors.error, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: GacColors.glassSurfaceStrong,
        indicatorColor: Color(0x332979FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GacColors.primary,
        foregroundColor: GacColors.white,
      ),
      cardTheme: const CardThemeData(
        color: GacColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: GacColors.panelShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: GacColors.panelBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: GacColors.primary,
          foregroundColor: GacColors.white,
          disabledBackgroundColor: const Color(0xFF153A56),
          disabledForegroundColor: GacColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.15,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? GacColors.primary
              : GacColors.cardSurface,
        ),
        side: const BorderSide(color: GacColors.border),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? GacColors.primary
              : GacColors.cardBorder,
        ),
        thumbColor: const WidgetStatePropertyAll(GacColors.white),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: GacColors.cardSurface,
        contentTextStyle: TextStyle(color: GacColors.textPrimary),
      ),
    );
  }
}
