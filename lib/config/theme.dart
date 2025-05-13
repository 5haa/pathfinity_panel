import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary color palette
  static const Color primaryColor = Color(0xFF1E40AF); // Deeper blue
  static const Color primaryLightColor = Color(0xFF3B82F6); // Lighter blue
  static const Color primaryDarkColor = Color(0xFF1E3A8A); // Darker blue
  static const Color secondaryColor = Color(0xFF475569); // Slate gray

  // Accent colors
  static const Color accentColor = Color(0xFF3B82F6); // Blue (matching primary)
  static const Color accentLightColor = Color(0xFF60A5FA); // Lighter blue
  static const Color accentDarkColor = Color(0xFF2563EB); // Darker blue

  // Background colors
  static const Color backgroundColor = Color(0xFFF8FAFC); // Light gray-blue
  static const Color surfaceColor = Colors.white; // Pure white
  static const Color cardColor = Colors.white; // Card color

  // Status colors
  static const Color errorColor = Color(0xFFDC2626); // Red
  static const Color successColor = Color(0xFF059669); // Emerald green
  static const Color warningColor = Color(0xFFD97706); // Amber
  static const Color infoColor = Color(0xFF0284C7); // Sky blue

  // Text colors
  static const Color textColor = Color(0xFF0F172A); // Slate 900
  static const Color textLightColor = Color(0xFF64748B); // Slate 500
  static const Color textInverseColor =
      Colors.white; // White text for dark backgrounds

  // Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1E293B).withOpacity(0.08),
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textColor,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColor,
    letterSpacing: 0.1,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: textLightColor,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLightColor,
        secondary: accentColor,
        secondaryContainer: accentLightColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shadowColor: const Color(0xFF1E293B).withOpacity(0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: subheadingStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: buttonTextStyle.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: secondaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: secondaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        errorStyle: const TextStyle(color: errorColor, fontSize: 12),
        hintStyle: TextStyle(
          color: textLightColor.withOpacity(0.7),
          fontSize: 15,
        ),
        labelStyle: const TextStyle(color: textLightColor, fontSize: 16),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondaryColor,
        suffixIconColor: secondaryColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.white;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected))
            return primaryColor.withOpacity(0.5);
          return secondaryColor.withOpacity(0.3);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryColor.withOpacity(0.2),
        thickness: 1,
        space: 32,
      ),
      textTheme: const TextTheme(
        displayLarge: headingStyle,
        displayMedium: subheadingStyle,
        bodyLarge: bodyStyle,
        bodyMedium: captionStyle,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDarkColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
