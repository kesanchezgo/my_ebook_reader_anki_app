import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;
  
  // Notifier for global theme changes
  final ValueNotifier<String> themeNotifier = ValueNotifier<String>(AppTheme.darkPremium);

  // Keys
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontSize = 'font_size';
  static const String _keyThemeId = 'theme_id';
  static const String _keyTextAlign = 'text_align';

  // Defaults
  static const String _defaultFontFamily = 'Merriweather';
  static const double _defaultFontSize = 18.0;
  static const String _defaultThemeId = AppTheme.darkPremium;
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

  // Themes Definition (Delegated to AppTheme)
  Map<String, AppTheme> get appThemes => AppTheme.themes;

  AppTheme get currentTheme => AppTheme.getTheme(_themeId);

  // Helpers para acceso directo a SharedPreferences (Síncrono)
  double? getDouble(String key) => _prefs?.getDouble(key);
  Future<void> setDouble(String key, double value) async => await _prefs?.setDouble(key, value);
  int? getInt(String key) => _prefs?.getInt(key);
  Future<void> setInt(String key, int value) async => await _prefs?.setInt(key, value);

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
    
    // Update notifier
    themeNotifier.value = _themeId;
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
    if (AppTheme.themes.containsKey(value)) {
      _themeId = value;
      themeNotifier.value = value; // Notify listeners
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
