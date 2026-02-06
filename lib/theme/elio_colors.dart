import 'package:flutter/material.dart';

class ElioColors {
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF313134);
  static const Color darkPrimaryText = Color(0xFFF9DFC1);
  static const Color darkAccent = Color(0xFFFF6436);
  static const Color darkFocus = Color(0xFFFF3607);

  static const Color lightBackground = Color(0xFFF9DFC1);
  static const Color lightSurface = Color(0xFFFFF4E6);
  static const Color lightPrimaryText = Color(0xFF1C1C1E);
  static const Color lightSecondaryText = Color(0xFF313134);
  static const Color lightAccent = Color(0xFFFF6436);
  static const Color lightFocus = Color(0xFFFF3607);

  static Color darkSecondaryText(double opacity) =>
      darkPrimaryText.withOpacity(opacity);
}
