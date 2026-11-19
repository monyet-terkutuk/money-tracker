import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Luxury Obsidian & Warm Copper palette.
class AppPalette {
  // Core & Accent
  static const Color charcoalInk = Color(0xFF141210);
  static const Color burnishedBrass = Color(0xFFC26D47);
  static const Color burnishedBrassDark = Color(0xFFE08E67);

  // Light Surfaces (Warm Alabaster White)
  static const Color lightBackground = Color(0xFFFAF8F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF2EDE6);
  static const Color lightBorder = Color(0xFFE6DFD5);
  static const Color lightTextPrimary = Color(0xFF141210);
  static const Color lightTextSecondary = Color(0xFF6E675F);

  // Dark Surfaces (Matte Obsidian)
  static const Color darkBackground = Color(0xFF0F0E0D);
  static const Color darkSurface = Color(0xFF181614);
  static const Color darkSurfaceVariant = Color(0xFF23201D);
  static const Color darkBorder = Color(0xFF2E2A26);
  static const Color darkTextPrimary = Color(0xFFF7F4EF);
  static const Color darkTextSecondary = Color(0xFF9C948B);

  // Semantic
  static const Color incomeLight = Color(0xFF15803D);
  static const Color incomeDark = Color(0xFF4ADE80);
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color expenseLight = Color(0xFFB91C1C);
  static const Color expenseDark = Color(0xFFF87171);

  // Backwards-compatible aliases
  static const Color deepEmerald = charcoalInk;
  static const Color champagneGold = burnishedBrass;
  static const Color champagneGoldLight = burnishedBrassDark;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? burnishedBrassDark
          : burnishedBrass;

  static Color incomeColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeDark : incomeLight;

  static Color warningColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? warningDark
          : warningLight;

  static Color expenseColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? expenseDark
          : expenseLight;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color secondaryTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.charcoalInk,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.lightSurfaceVariant,
      onPrimaryContainer: AppPalette.charcoalInk,
      secondary: AppPalette.burnishedBrass,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF9EBE4),
      onSecondaryContainer: Color(0xFF5C2A14),
      tertiary: AppPalette.burnishedBrass,
      onTertiary: Colors.white,
      error: AppPalette.expenseLight,
      onError: Colors.white,
      surface: AppPalette.lightSurface,
      onSurface: AppPalette.lightTextPrimary,
      surfaceContainerHighest: AppPalette.lightSurfaceVariant,
      onSurfaceVariant: AppPalette.lightTextSecondary,
      outline: AppPalette.lightBorder,
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).apply(
      bodyColor: AppPalette.lightTextPrimary,
      displayColor: AppPalette.lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: AppPalette.lightBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppPalette.lightBackground,
        foregroundColor: AppPalette.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.lightTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppPalette.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.charcoalInk, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.charcoalInk,
          foregroundColor: AppPalette.lightSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.lightTextPrimary,
          side: const BorderSide(color: AppPalette.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.charcoalInk,
        foregroundColor: AppPalette.lightSurface,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.lightBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.lightSurface,
        selectedColor: AppPalette.burnishedBrass.withValues(alpha: 0.12),
        side: const BorderSide(color: AppPalette.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        labelStyle: const TextStyle(
          color: AppPalette.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.darkTextPrimary,
      onPrimary: AppPalette.darkBackground,
      primaryContainer: AppPalette.darkSurfaceVariant,
      onPrimaryContainer: AppPalette.darkTextPrimary,
      secondary: AppPalette.burnishedBrassDark,
      onSecondary: Color(0xFF141210),
      secondaryContainer: Color(0xFF2D1D16),
      onSecondaryContainer: Color(0xFFF3B79B),
      tertiary: AppPalette.burnishedBrassDark,
      onTertiary: Color(0xFF141210),
      error: AppPalette.expenseDark,
      onError: Color(0xFF2D0A0A),
      surface: AppPalette.darkSurface,
      onSurface: AppPalette.darkTextPrimary,
      surfaceContainerHighest: AppPalette.darkSurfaceVariant,
      onSurfaceVariant: AppPalette.darkTextSecondary,
      outline: AppPalette.darkBorder,
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: AppPalette.darkTextPrimary,
      displayColor: AppPalette.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: AppPalette.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppPalette.darkBackground,
        foregroundColor: AppPalette.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppPalette.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppPalette.burnishedBrassDark,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.burnishedBrassDark,
          foregroundColor: AppPalette.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.darkTextPrimary,
          side: const BorderSide(color: AppPalette.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.burnishedBrassDark,
        foregroundColor: AppPalette.darkBackground,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.darkBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.darkSurface,
        selectedColor: AppPalette.burnishedBrassDark.withValues(alpha: 0.18),
        side: const BorderSide(color: AppPalette.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        labelStyle: const TextStyle(
          color: AppPalette.darkTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
