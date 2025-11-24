import 'dart:io';
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
  // Notifier for global locale changes
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

  // Keys
  static const String _keyFontFamily = 'font_family';
  static const String _keyFontSize = 'font_size';
  static const String _keyThemeId = 'theme_id';
  static const String _keyLocale = 'app_locale';
  static const String _keyTextAlign = 'text_align';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyPerplexityApiKey = 'perplexity_api_key';
  static const String _keyOpenRouterApiKey = 'openrouter_api_key';
  static const String _keyDictionaryPriority = 'dictionary_priority';
  static const String _keyContextPriority = 'context_priority';
  static const String _keyStudyMode = 'study_mode';

  // Defaults
  static const String _defaultFontFamily = 'Merriweather';
  static const double _defaultFontSize = 18.0;
  static const String _defaultThemeId = AppTheme.darkPremium;
  // static const String? _defaultLocale = null; // Removed in favor of dynamic default
  static const String _defaultTextAlign = 'justify';
  static const String _defaultGeminiApiKey = '';
  static const String _defaultPerplexityApiKey = '';
  static const String _defaultOpenRouterApiKey = '';
  static const List<String> _defaultDictionaryPriority = ['gemini', 'perplexity', 'openrouter', 'local', 'web'];
  static const List<String> _defaultContextPriority = ['gemini', 'perplexity', 'openrouter'];
  static const String _defaultStudyMode = 'native';

  // Current State
  String _fontFamily = _defaultFontFamily;
  double _fontSize = _defaultFontSize;
  String _themeId = _defaultThemeId;
  String? _localeCode; // Initialized in loadSettings
  String _textAlign = _defaultTextAlign;
  String _geminiApiKey = _defaultGeminiApiKey;
  String _perplexityApiKey = _defaultPerplexityApiKey;
  String _openRouterApiKey = _defaultOpenRouterApiKey;
  List<String> _dictionaryPriority = _defaultDictionaryPriority;
  List<String> _contextPriority = _defaultContextPriority;
  String _studyMode = _defaultStudyMode;

  // Getters
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  String get themeId => _themeId;
  Locale? get locale => _localeCode != null ? Locale(_localeCode!) : null;
  String get textAlign => _textAlign;
  String get geminiApiKey => _geminiApiKey;
  String get perplexityApiKey => _perplexityApiKey;
  String get openRouterApiKey => _openRouterApiKey;
  List<String> get dictionaryPriority => _dictionaryPriority;
  List<String> get contextPriority => _contextPriority;
  String get studyMode => _studyMode;

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
    
    // Language Logic: Best Match or English
    final String? savedLocale = _prefs!.getString(_keyLocale);
    if (savedLocale != null) {
      _localeCode = savedLocale;
    } else {
      // First run logic
      try {
        final String systemLocale = Platform.localeName.split('_')[0];
        if (['es', 'en'].contains(systemLocale)) {
          _localeCode = systemLocale;
        } else {
          _localeCode = 'en'; // Fallback to English
        }
        debugPrint('[LANG_DEBUG] System: $systemLocale, Selected: $_localeCode');
      } catch (e) {
        _localeCode = 'en';
        debugPrint('[LANG_DEBUG] Error getting system locale: $e, Selected: $_localeCode');
      }
    }

    _textAlign = _prefs!.getString(_keyTextAlign) ?? _defaultTextAlign;
    _geminiApiKey = _prefs!.getString(_keyGeminiApiKey) ?? _defaultGeminiApiKey;
    _perplexityApiKey = _prefs!.getString(_keyPerplexityApiKey) ?? _defaultPerplexityApiKey;
    _openRouterApiKey = _prefs!.getString(_keyOpenRouterApiKey) ?? _defaultOpenRouterApiKey;
    _dictionaryPriority = _prefs!.getStringList(_keyDictionaryPriority) ?? _defaultDictionaryPriority;
    _contextPriority = _prefs!.getStringList(_keyContextPriority) ?? _defaultContextPriority;
    _studyMode = _prefs!.getString(_keyStudyMode) ?? _defaultStudyMode;

    // Migración: Asegurar que todas las opciones por defecto estén en la lista (para nuevos proveedores como openrouter)
    bool changed = false;
    
    // Migración Contexto
    for (final defaultItem in _defaultContextPriority) {
      if (!_contextPriority.contains(defaultItem)) {
        _contextPriority.add(defaultItem);
        changed = true;
      }
    }
    if (changed) {
      await _prefs!.setStringList(_keyContextPriority, _contextPriority);
    }

    // Migración Diccionario
    bool dictChanged = false;
    for (final defaultItem in _defaultDictionaryPriority) {
      if (!_dictionaryPriority.contains(defaultItem)) {
        // Insertar al principio si son IAs, o manejar lógica específica. 
        // Por simplicidad, añadimos al final si no existen, pero idealmente las IAs van antes de local/web si el usuario no ha personalizado mucho.
        // Si la lista es la antigua ['gemini', 'local', 'web'], queremos insertar perplexity y openrouter después de gemini.
        if (defaultItem == 'perplexity' || defaultItem == 'openrouter') {
           int geminiIndex = _dictionaryPriority.indexOf('gemini');
           if (geminiIndex != -1) {
             _dictionaryPriority.insert(geminiIndex + 1, defaultItem);
           } else {
             _dictionaryPriority.insert(0, defaultItem);
           }
        } else {
          _dictionaryPriority.add(defaultItem);
        }
        dictChanged = true;
      }
    }
    if (dictChanged) {
      await _prefs!.setStringList(_keyDictionaryPriority, _dictionaryPriority);
    }
    
    // Update notifiers
    themeNotifier.value = _themeId;
    localeNotifier.value = locale;
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

  /// Guarda el idioma de la app
  Future<void> setLocale(String languageCode) async {
    _localeCode = languageCode;
    localeNotifier.value = locale; // Notify listeners
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyLocale, languageCode);
  }

  /// Guarda la alineación del texto
  Future<void> setTextAlign(String value) async {
    _textAlign = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyTextAlign, value);
  }

  /// Guarda la API Key de Gemini
  Future<void> setGeminiApiKey(String value) async {
    _geminiApiKey = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyGeminiApiKey, value);
  }

  /// Guarda la API Key de Perplexity
  Future<void> setPerplexityApiKey(String value) async {
    _perplexityApiKey = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyPerplexityApiKey, value);
  }

  /// Guarda la API Key de OpenRouter
  Future<void> setOpenRouterApiKey(String value) async {
    _openRouterApiKey = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyOpenRouterApiKey, value);
  }

  /// Guarda la prioridad de diccionarios
  Future<void> setDictionaryPriority(List<String> value) async {
    _dictionaryPriority = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_keyDictionaryPriority, value);
  }

  /// Guarda la prioridad de contexto
  Future<void> setContextPriority(List<String> value) async {
    _contextPriority = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_keyContextPriority, value);
  }

  /// Guarda el modo de estudio ('native' o 'learning')
  Future<void> setStudyMode(String value) async {
    _studyMode = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyStudyMode, value);
  }

  /// Restaura los valores por defecto
  Future<void> resetToDefaults() async {
    await setFontFamily(_defaultFontFamily);
    await setFontSize(_defaultFontSize);
    await setThemeId(_defaultThemeId);
    await setTextAlign(_defaultTextAlign);
    await setGeminiApiKey(_defaultGeminiApiKey);
    await setPerplexityApiKey(_defaultPerplexityApiKey);
    await setOpenRouterApiKey(_defaultOpenRouterApiKey);
    await setDictionaryPriority(_defaultDictionaryPriority);
    await setContextPriority(_defaultContextPriority);
    await setStudyMode(_defaultStudyMode);
  }

  /// Restaura solo la configuración de lectura (fuente, tamaño, alineación)
  Future<void> resetReaderSettings() async {
    await setFontFamily(_defaultFontFamily);
    await setFontSize(_defaultFontSize);
    await setTextAlign(_defaultTextAlign);
    // No reseteamos el tema ni las API keys
  }
}
