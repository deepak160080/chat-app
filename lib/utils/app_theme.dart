

import 'package:chat_app/services/constants.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLightColor,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: AppColors.errorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.archivo(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.archivo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: GoogleFonts.archivo(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: GoogleFonts.archivo(
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.archivo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.primaryColor,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerColor,
      thickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLightColor,
      onSecondary: Colors.white,
      surface: AppColors.surfaceColor,
      onSurface: Colors.white,
      error: AppColors.errorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Constants.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.archivo(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.archivo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.archivo(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: GoogleFonts.archivo(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.archivo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.iconColor,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerColor,
      thickness: 1,
    ),
  );
}