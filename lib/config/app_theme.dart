import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final String id;
  final String name;
  final Color backgroundColor; // Para el Lector
  final Color textColor;       // Para el Lector
  final ThemeData themeData;   // Para la App Global

  const AppTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.themeData,
  });

  static const String darkPremium = 'dark_premium';
  static const String midnightBlue = 'midnight_blue';
  static const String oledTrueBlack = 'oled_true_black';
  static const String warmSepia = 'warm_sepia';
  static const String softLight = 'soft_light';

  static final Map<String, AppTheme> themes = {
    darkPremium: _buildTheme(
      id: darkPremium,
      name: 'Dark Premium',
      bg: const Color(0xFF121212),
      card: const Color(0xFF1E1E1E),
      text: const Color(0xFFE0E0E0),
      isDark: true,
    ),
    midnightBlue: _buildTheme(
      id: midnightBlue,
      name: 'Midnight Blue',
      bg: const Color(0xFF0F172A),
      card: const Color(0xFF1E293B),
      text: const Color(0xFF94A3B8),
      isDark: true,
    ),
    oledTrueBlack: _buildTheme(
      id: oledTrueBlack,
      name: 'OLED True Black',
      bg: const Color(0xFF000000),
      card: const Color(0xFF121212),
      text: const Color(0xFFA0A0A0),
      isDark: true,
    ),
    warmSepia: _buildTheme(
      id: warmSepia,
      name: 'Warm Sepia',
      bg: const Color(0xFFF5E6D3),
      card: const Color(0xFFE6D5C1),
      text: const Color(0xFF5F4B32),
      isDark: false,
    ),
    softLight: _buildTheme(
      id: softLight,
      name: 'Soft Light',
      bg: const Color(0xFFFFFFFF),
      card: const Color(0xFFF5F5F5),
      text: const Color(0xFF333333),
      isDark: false,
    ),
  };

  static AppTheme getTheme(String themeId) => themes[themeId] ?? themes[darkPremium]!;

  static AppTheme _buildTheme({
    required String id,
    required String name,
    required Color bg,
    required Color card,
    required Color text,
    required bool isDark,
    Color? primary,
  }) {
    // Lógica de color "Premium" adaptativo
    // Oscuro: Dorado Metálico (Metallic Gold) para menos fatiga visual.
    // Claro: Azul Índigo Profundo para legibilidad sobre blanco/sepia.
    final primaryColor = primary ?? (isDark ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50));
    
    // Color secundario para acentos (ej. botones flotantes, sliders)
    final secondaryColor = isDark ? const Color(0xFF64FFDA) : const Color(0xFFE67E22);

    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: card,
            onSurface: text,
            background: bg,
            error: const Color(0xFFCF6679),
          )
        : ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: card,
            onSurface: text,
            background: bg,
            error: const Color(0xFFB00020),
          );

    return AppTheme(
      id: id,
      name: name,
      backgroundColor: bg,
      textColor: text,
      themeData: ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: primaryColor,
        colorScheme: colorScheme,
        // cardTheme removed to avoid type error
        appBarTheme: AppBarTheme(
          backgroundColor: card.withOpacity(0.95),
          foregroundColor: text,
          elevation: 0,
          iconTheme: IconThemeData(color: primaryColor),
          actionsIconTheme: IconThemeData(color: primaryColor),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
        iconTheme: IconThemeData(color: primaryColor),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
        ),
        textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme).apply(
          bodyColor: text,
          displayColor: text,
        ),
      ),
    );
  }
}
