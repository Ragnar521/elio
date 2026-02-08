import 'package:flutter/material.dart';

import 'elio_colors.dart';
import 'elio_text_theme.dart';

class ElioTheme {
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: ElioColors.darkAccent,
      secondary: ElioColors.darkFocus,
      background: ElioColors.darkBackground,
      surface: ElioColors.darkSurface,
      onPrimary: ElioColors.darkBackground,
      onSecondary: ElioColors.darkBackground,
      onBackground: ElioColors.darkPrimaryText,
      onSurface: ElioColors.darkPrimaryText,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ElioColors.darkBackground,
      textTheme: ElioTextTheme.forDark(),
      appBarTheme: const AppBarTheme(
        backgroundColor: ElioColors.darkSurface,
        foregroundColor: ElioColors.darkPrimaryText,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: ElioColors.darkSurface,
        elevation: 0,
      ),
      dividerColor: ElioColors.darkPrimaryText.withOpacity(0.08),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ElioColors.darkSurface,
        selectedItemColor: ElioColors.darkAccent,
        unselectedItemColor: ElioColors.darkPrimaryText.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: const IconThemeData(
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          size: 22,
        ),
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: ElioColors.lightAccent,
      secondary: ElioColors.lightFocus,
      background: ElioColors.lightBackground,
      surface: ElioColors.lightSurface,
      onPrimary: ElioColors.lightBackground,
      onSecondary: ElioColors.lightBackground,
      onBackground: ElioColors.lightPrimaryText,
      onSurface: ElioColors.lightPrimaryText,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ElioColors.lightBackground,
      textTheme: ElioTextTheme.forLight(),
      appBarTheme: const AppBarTheme(
        backgroundColor: ElioColors.lightSurface,
        foregroundColor: ElioColors.lightPrimaryText,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: ElioColors.lightSurface,
        elevation: 0,
      ),
      dividerColor: ElioColors.lightPrimaryText.withOpacity(0.08),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ElioColors.lightSurface,
        selectedItemColor: ElioColors.lightAccent,
        unselectedItemColor: ElioColors.lightPrimaryText.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        selectedIconTheme: const IconThemeData(
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          size: 22,
        ),
      ),
    );
  }
}
