import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: AppColors.primaryLightColor,
    fontFamily: 'poppins',
    textTheme:  TextTheme(
      ///Used at splash
      headlineLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
      ),
      ///Used at languageselect
      titleLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
      ),
      ///Used at home

      titleMedium: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
      ),
      ///Used at languageselect hint

      titleSmall: TextStyle(
        color: AppColors.textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      ///Used as title in popups
      bodyLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
///used at home
      bodyMedium: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      ///Used at splash
      bodySmall: TextStyle(
        color: AppColors.greytextColor,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,

      ),
    ),
    textSelectionTheme:  TextSelectionThemeData(
        cursorColor: AppColors.primaryColor.withValues(alpha: 0.5),
        selectionColor: AppColors.primaryColor.withAlpha(50),
        selectionHandleColor: AppColors.primaryColor.withAlpha(50)

    ),
    colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
         onPrimary: AppColors.textColor,
        // secondary: AppColors.headingColor,
        onSecondary: AppColors.buttonTextColor,
        tertiary: AppColors.primaryLightColor

    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.buttonTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
  );
  static ThemeData DarkTheme = ThemeData(
    brightness: Brightness.dark,


    scaffoldBackgroundColor: AppColors.textColor,
    fontFamily: 'poppins',
    textTheme:  TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.32,
      ),
      titleLarge: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.32,
      ),
      titleMedium: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),

      bodyMedium: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.buttonTextColor,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    textSelectionTheme:  TextSelectionThemeData(
        cursorColor: AppColors.primaryColor.withValues(alpha: 0.5),
        selectionColor: AppColors.primaryColor.withAlpha(50),
        selectionHandleColor: AppColors.primaryColor.withAlpha(50)

    ),
    colorScheme: ColorScheme.dark(
        primary: AppColors.primaryColor,
        onPrimary: AppColors.textColor,
        secondary: AppColors.buttonTextColor,
        onSecondary: AppColors.textColor,
        tertiary: AppColors.textColor


    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.buttonTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
  );
}