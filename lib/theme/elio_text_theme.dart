import 'package:flutter/material.dart';

class ElioTextTheme {
  static TextTheme forDark() {
    const headingColor = Color(0xFFF9DFC1);
    final bodyColor = headingColor.withOpacity(0.75);

    final base = ThemeData(brightness: Brightness.dark)
        .textTheme
        .apply(displayColor: headingColor.withOpacity(0.95), bodyColor: bodyColor);

    return _withLineHeight(base, 1.35);
  }

  static TextTheme forLight() {
    const headingColor = Color(0xFF1C1C1E);
    const bodyColor = Color(0xFF313134);

    final base = ThemeData(brightness: Brightness.light)
        .textTheme
        .apply(displayColor: headingColor.withOpacity(0.95), bodyColor: bodyColor.withOpacity(0.8));

    return _withLineHeight(base, 1.35);
  }

  static TextTheme _withLineHeight(TextTheme base, double height) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(height: height),
      displayMedium: base.displayMedium?.copyWith(height: height),
      displaySmall: base.displaySmall?.copyWith(height: height),
      headlineLarge: base.headlineLarge?.copyWith(height: height),
      headlineMedium: base.headlineMedium?.copyWith(height: height),
      headlineSmall: base.headlineSmall?.copyWith(height: height),
      titleLarge: base.titleLarge?.copyWith(height: height),
      titleMedium: base.titleMedium?.copyWith(height: height),
      titleSmall: base.titleSmall?.copyWith(height: height),
      bodyLarge: base.bodyLarge?.copyWith(height: height),
      bodyMedium: base.bodyMedium?.copyWith(height: height),
      bodySmall: base.bodySmall?.copyWith(height: height),
      labelLarge: base.labelLarge?.copyWith(height: height),
      labelMedium: base.labelMedium?.copyWith(height: height),
      labelSmall: base.labelSmall?.copyWith(height: height),
    );
  }
}
