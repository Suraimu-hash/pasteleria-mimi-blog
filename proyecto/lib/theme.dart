import 'package:flutter/material.dart';

/// Identidad visual de Pastelería Mimi.
class Mimi {
  static const Color rosa = Color(0xFFE0568A);
  static const Color frambuesa = Color(0xFF6D2E46);
  static const Color crema = Color(0xFFFFF7F0);
  static const Color rosaClaro = Color(0xFFFFD9E6);
  static const Color durazno = Color(0xFFFFE8D6);
  static const Color cacao = Color(0xFF3E2723);
  static const Color gris = Color(0xFF7A6A69);

  static ThemeData tema() {
    final esquema = ColorScheme.fromSeed(
      seedColor: rosa,
      primary: rosa,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: crema,
      appBarTheme: const AppBarTheme(
        backgroundColor: frambuesa,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rosa,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rosa,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: rosa, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
