import 'package:flutter/material.dart';

mixin CustomStyle {
  // Gradient Background
  Gradient get backgroundGradient => const LinearGradient(
        colors: [Color(0xFF200A4C), Color(0xFF551A8B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // Text Styles
  TextStyle get titleStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  TextStyle get descriptionStyle => const TextStyle(
        fontSize: 16,
        color: Colors.white,
      );

  TextStyle get buttonTextStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  TextStyle get interestLabelStyle =>const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      );

  // Interest Card Decoration
  BoxDecoration get interestCardDecoration => BoxDecoration(
        color: Colors.white.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
      );
  TextStyle get navButtonStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
  // Button Decoration (Gradient)
  BoxDecoration get buttonDecoration => BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E1A78), Color(0xFF6D35A5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
      );
}
