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

  /// Gradient nawigacji (dolny pasek telefonu i boczna szyna tabletu):
  /// jasno-niebieski (góra) → indygo (dół). Lekki i elegancki; ikony/etykiety
  /// są w bieli, więc pozostają czytelne na indygo w dolnej części.
  static const List<Color> navBarGradient = [
    Color(0xFFC7D2FE), // jasno-niebieski
    Color(0xFF6366F1), // indygo
    Color(0xFF4F46E5), // głębsze indygo
  ];

  /// Złote akcenty nawigacji (subtelne linie/ornamenty, wskaźnik zaznaczenia).
  static const Color gold = Color(0xFFCBA24B);
  static const Color goldLight = Color(0xFFE6C878);

  /// Gradient złotej linii/ornamentu.
  static const List<Color> goldGradient = [
    Color(0xFFE6C878),
    Color(0xFFB8860B),
  ];
}
