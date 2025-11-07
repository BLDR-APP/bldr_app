import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the fitness application.
/// Implements Premium Minimalist Fitness design with Luxury Athletic color scheme.
class AppTheme {
  AppTheme._();

  // Luxury Athletic Color Palette
  static const Color primaryBlack = Color(0xFF000000);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textVariant = Color(0xFF000000);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color dividerGray = Color(0xFF2C2C2C);
  static const Color inactiveGray = Color(0xFF666666);

  // Additional semantic colors
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF2D2D2D);
  static const Color shadowBlack = Color(0x33000000); // 20% opacity
  static const Color overlayBlack = Color(0x80000000); // 50% opacity

  /// Light theme (minimal usage for fitness app)
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryBlack,
      onPrimary: textPrimary,
      primaryContainer: surfaceDark,
      onPrimaryContainer: textPrimary,
      secondary: accentGold,
      onSecondary: primaryBlack,
      secondaryContainer: accentGold.withValues(alpha: 0.2),
      onSecondaryContainer: primaryBlack,
      tertiary: successGreen,
      onTertiary: textPrimary,
      tertiaryContainer: successGreen.withValues(alpha: 0.2),
      onTertiaryContainer: primaryBlack,
      error: errorRed,
      onError: textPrimary,
      surface: Color(0xFFF5F5F5),
      onSurface: primaryBlack,
      onSurfaceVariant: textSecondary,
      outline: dividerGray,
      outlineVariant: inactiveGray,
      shadow: shadowBlack,
      scrim: overlayBlack,
      inverseSurface: primaryBlack,
      onInverseSurface: textPrimary,
      inversePrimary: accentGold,
    ),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    cardColor: Color(0xFFFFFFFF),
    dividerColor: dividerGray,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFFFFFFFF),
      elevation: 2.0,
      shadowColor: shadowBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryBlack,
      selectedItemColor: accentGold,
      unselectedItemColor: inactiveGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8.0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentGold,
      foregroundColor: primaryBlack,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryBlack,
        backgroundColor: accentGold,
        elevation: 2.0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: primaryBlack, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: true),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Color(0xFFF8F8F8),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: accentGold, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRed, width: 2.0),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: inactiveGray,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return inactiveGray;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold.withValues(alpha: 0.3);
        }
        return inactiveGray.withValues(alpha: 0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(primaryBlack),
      side: BorderSide(color: dividerGray, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return inactiveGray;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentGold,
      linearTrackColor: dividerGray,
      circularTrackColor: dividerGray,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentGold,
      thumbColor: accentGold,
      overlayColor: accentGold.withValues(alpha: 0.2),
      inactiveTrackColor: dividerGray,
      trackHeight: 4.0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentGold,
      unselectedLabelColor: inactiveGray,
      indicatorColor: accentGold,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: primaryBlack.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryBlack,
      contentTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ), dialogTheme: DialogThemeData(backgroundColor: Color(0xFFFFFFFF)),
  );

  /// Dark theme (primary theme for fitness app)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: accentGold,
      onPrimary: primaryBlack,
      primaryContainer: accentGold.withValues(alpha: 0.2),
      onPrimaryContainer: textPrimary,
      secondary: successGreen,
      onSecondary: primaryBlack,
      secondaryContainer: successGreen.withValues(alpha: 0.2),
      onSecondaryContainer: textPrimary,
      tertiary: warningAmber,
      onTertiary: primaryBlack,
      tertiaryContainer: warningAmber.withValues(alpha: 0.2),
      onTertiaryContainer: textPrimary,
      error: errorRed,
      onError: textPrimary,
      surface: surfaceDark,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: dividerGray,
      outlineVariant: inactiveGray,
      shadow: shadowBlack,
      scrim: overlayBlack,
      inverseSurface: textPrimary,
      onInverseSurface: primaryBlack,
      inversePrimary: primaryBlack,
    ),
    scaffoldBackgroundColor: primaryBlack,
    cardColor: cardDark,
    dividerColor: dividerGray,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2.0,
      shadowColor: shadowBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: accentGold,
      unselectedItemColor: inactiveGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8.0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentGold,
      foregroundColor: primaryBlack,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryBlack,
        backgroundColor: accentGold,
        elevation: 2.0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentGold,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: accentGold, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentGold,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: false),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: accentGold, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRed, width: 2.0),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: inactiveGray,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return inactiveGray;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold.withValues(alpha: 0.3);
        }
        return inactiveGray.withValues(alpha: 0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(primaryBlack),
      side: BorderSide(color: dividerGray, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentGold;
        }
        return inactiveGray;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentGold,
      linearTrackColor: dividerGray,
      circularTrackColor: dividerGray,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentGold,
      thumbColor: accentGold,
      overlayColor: accentGold.withValues(alpha: 0.2),
      inactiveTrackColor: dividerGray,
      trackHeight: 4.0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentGold,
      unselectedLabelColor: inactiveGray,
      indicatorColor: accentGold,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ), dialogTheme: DialogThemeData(backgroundColor: dialogDark),
  );

  /// Helper method to build text theme based on brightness
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight ? primaryBlack : textPrimary;
    final Color textMediumEmphasis =
        isLight ? primaryBlack.withValues(alpha: 0.7) : textSecondary;
    final Color textDisabled =
        isLight ? primaryBlack.withValues(alpha: 0.4) : inactiveGray;

    return TextTheme(
      // Display styles - for large headings and hero text
      displayLarge: GoogleFonts.montserrat(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
      ),

      // Headline styles - for section headers
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
      ),

      // Title styles - for card headers and important text
      titleLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),

      // Body styles - for main content
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
        letterSpacing: 0.4,
      ),

      // Label styles - for buttons and small text
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textDisabled,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Data text theme using JetBrains Mono for numerical data
  static TextTheme dataTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight ? primaryBlack : textPrimary;
    final Color textMediumEmphasis =
        isLight ? primaryBlack.withValues(alpha: 0.7) : textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
      ),
      displayMedium: GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
      ),
      displaySmall: GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
      ),
      headlineLarge: GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
      ),
      headlineMedium: GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
      ),
      bodyLarge: GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
      ),
      bodyMedium: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
      ),
    );
  }
}
