import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;

  const AppTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
  });
}

class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Keys
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontSize = 'font_size';
  static const String _keyThemeId = 'theme_id';
  static const String _keyTextAlign = 'text_align';

  // Defaults
  static const String _defaultFontFamily = 'Merriweather';
  static const double _defaultFontSize = 18.0;
  static const String _defaultThemeId = 'dark_pro';
  static const String _defaultTextAlign = 'justify';

  // Current State
  String _fontFamily = _defaultFontFamily;
  double _fontSize = _defaultFontSize;
  String _themeId = _defaultThemeId;
  String _textAlign = _defaultTextAlign;

  // Getters
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  String get themeId => _themeId;
  String get textAlign => _textAlign;

  // Themes Definition
  static const Map<String, AppTheme> _themes = {
    'dark_pro': AppTheme(
      id: 'dark_pro',
      name: 'Dark Pro',
      backgroundColor: Color(0xFF121212),
      textColor: Color(0xFFE0E0E0),
    ),
    'midnight_blue': AppTheme(
      id: 'midnight_blue',
      name: 'Midnight Blue',
      backgroundColor: Color(0xFF15202B),
      textColor: Color(0xFF8899A6),
    ),
    'deep_slate': AppTheme(
      id: 'deep_slate',
      name: 'Deep Slate',
      backgroundColor: Color(0xFF1E1E1E),
      textColor: Color(0xFFD4D4D4),
    ),
    'oled_black': AppTheme(
      id: 'oled_black',
      name: 'OLED True Black',
      backgroundColor: Color(0xFF000000),
      textColor: Color(0xFFA0A0A0),
    ),
    'soft_sepia': AppTheme(
      id: 'soft_sepia',
      name: 'Soft Sepia',
      backgroundColor: Color(0xFFF5E6D3),
      textColor: Color(0xFF5F4B32),
    ),
  };

  Map<String, AppTheme> get appThemes => _themes;

  AppTheme get currentTheme => _themes[_themeId] ?? _themes[_defaultThemeId]!;

  /// Inicializa el servicio y carga las configuraciones
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadSettings();
  }

  /// Carga las configuraciones guardadas
  Future<void> loadSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    _fontFamily = _prefs!.getString(_keyFontFamily) ?? _defaultFontFamily;
    _fontSize = _prefs!.getDouble(_keyFontSize) ?? _defaultFontSize;
    _themeId = _prefs!.getString(_keyThemeId) ?? _defaultThemeId;
    _textAlign = _prefs!.getString(_keyTextAlign) ?? _defaultTextAlign;
  }

  /// Guarda el tipo de fuente
  Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyFontFamily, value);
  }

  /// Guarda el tamaño de fuente
  Future<void> setFontSize(double value) async {
    _fontSize = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_keyFontSize, value);
  }

  /// Guarda el tema seleccionado
  Future<void> setThemeId(String value) async {
    if (_themes.containsKey(value)) {
      _themeId = value;
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_keyThemeId, value);
    }
  }

  /// Guarda la alineación del texto
  Future<void> setTextAlign(String value) async {
    _textAlign = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyTextAlign, value);
  }

  /// Restaura los valores por defecto
  Future<void> resetToDefaults() async {
    await setFontFamily(_defaultFontFamily);
    await setFontSize(_defaultFontSize);
    await setThemeId(_defaultThemeId);
    await setTextAlign(_defaultTextAlign);
  }
}
