import 'package:flutter/material.dart';

/// Kolory przeniesione z aplikacji webowej (zmienne CSS w zrodlo-web/style.css).
class AppColors {
  static const Color accent = Color(0xFF1A56DB); // --accent
  static const Color accent2 = Color(0xFF3B82F6); // --accent-2
  static const Color text = Color(0xFF1A2744); // --text
  static const Color textLight = Color(0xFF5A6A8A); // --text-light

  /// Jasnoniebieski gradient tła aplikacji (--app-bg-gradient).
  static const List<Color> bgGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF4F8FE),
    Color(0xFFE8F1FC),
  ];

  /// Tło dekoracyjnej kreski pod tytułem karty logowania.
  static const List<Color> dividerGradient = [
    Color(0xFF1A56DB),
    Color(0xFF60A5FA),
  ];
}
