import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppTheme {
  // Color Palette - Hi Blankets Look
  static const Color primaryMaroon = Color(0xFF265D5E); // Deep Teal
  static const Color secondaryMaroon = Color(0xFF4A7A7B); // Soft Teal
  static const Color accentGold = Color(0xFFE6AF2E); // Warm Gold
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color creamWhite = Color(0xFFFDF8F0); // Light Cream
  static const Color charcoalGray = Color(0xFF2C3E50); // Dark Slate
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color shadowColor = Color(0x1A000000);

  //
  // static const Color primaryMaroon = Color(0xFFD32F2F);
  // static const Color secondaryMaroon = Color(0xFF5D4037);
  // static const Color accentGold = Color(0xFFD4AF37);
  // static const Color pureWhite = Color(0xFFFFFFFF);
  // static const Color creamWhite = Color(0xFFFFFBF5);
  // static const Color charcoalGray = Color(0xFF3E2723);
  // static const Color lightGray = Color(0xFFF5F5F5);
  // static const Color shadowColor = Color(0x1A000000);


  //





  // Font Configuration
  static const String englishFontFamily = 'Inter';
  static const String urduFontFamily = 'Jameel Noori Nastaleeq';
  static const String fallbackUrduFont = 'Noto Nastaliq Urdu';

  // Get font family based on locale
  static String getFontFamily(Locale locale) {
    if (locale.languageCode == 'ur') {
      return urduFontFamily;
    }
    return englishFontFamily;
  }

  // Light Theme with Locale Support
  static ThemeData getLightTheme(Locale locale) {
    final String fontFamily = getFontFamily(locale);
    final bool isUrdu = locale.languageCode == 'ur';

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryMaroon,
      scaffoldBackgroundColor: creamWhite,
      fontFamily: fontFamily,
      fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,

      colorScheme: const ColorScheme.light(
        primary: primaryMaroon,
        secondary: accentGold,
        surface: pureWhite,
        background: creamWhite,
        onPrimary: pureWhite,
        onSecondary: charcoalGray,
        onSurface: charcoalGray,
        onBackground: charcoalGray,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,
          fontSize: 4.sp,
          fontWeight: FontWeight.w700,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,
          fontSize: 3.5.sp,
          fontWeight: FontWeight.w600,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.sp,
          fontWeight: FontWeight.w600,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.5.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.sp, 
          fontWeight: FontWeight.w600,
          color: charcoalGray,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.sp,
          fontWeight: FontWeight.w400,
          color: charcoalGray,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w400,
          color: charcoalGray,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : 0.1,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: pureWhite,
          elevation: 6,
          shadowColor: primaryMaroon.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12.sp, // Using direct sp values to avoid context dependency
            fontWeight: FontWeight.w900,
            letterSpacing: isUrdu ? 0 : 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: charcoalGray,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        // Enforce dark text for input fields since fillColor is light
        suffixStyle: const TextStyle(color: charcoalGray),
        counterStyle: const TextStyle(color: charcoalGray),
        prefixStyle: const TextStyle(color: charcoalGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: charcoalGray, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF999999), width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGold, width: 3.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: const Color(0xFF444444),
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: charcoalGray,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w900,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryMaroon,
          fontWeight: FontWeight.w900,
          fontSize: 13.sp,
        ),
        prefixIconColor: primaryMaroon,
        suffixIconColor: primaryMaroon,
      ),

      // Changed to DialogThemeData to fix type mismatch in some Flutter versions
      dialogTheme: const DialogThemeData(
        backgroundColor: creamWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primaryMaroon,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: pureWhite,
      ),
    );
  }

  // Dark Theme with Locale Support
  static ThemeData getDarkTheme(Locale locale) {
    final String fontFamily = getFontFamily(locale);
    final bool isUrdu = locale.languageCode == 'ur';

    return getLightTheme(locale).copyWith(
      scaffoldBackgroundColor: const Color(0xFF111827),
      colorScheme: const ColorScheme.dark(
        primary: primaryMaroon,
        secondary: accentGold,
        surface: Color(0xFF1F2937),
        background: Color(0xFF111827),
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: pureWhite,
        onBackground: pureWhite,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 4.sp,
          fontWeight: FontWeight.w700,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.5.sp,
          fontWeight: FontWeight.w600,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.sp,
          fontWeight: FontWeight.w600,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.5.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: charcoalGray, // Force dark even in dark mode because input background is pureWhite
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.sp,
          fontWeight: FontWeight.w400,
          color: pureWhite,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w400,
          color: pureWhite,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : 0.1,
        ),
      ),
    );
  }

  // Backward compatibility - use Urdu by default
  // Changed default to English as per request
  static ThemeData get lightTheme => getLightTheme(const Locale('en'));
  static ThemeData get darkTheme => getDarkTheme(const Locale('en'));
}
