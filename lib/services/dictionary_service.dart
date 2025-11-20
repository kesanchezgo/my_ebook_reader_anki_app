import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_dictionary_service.dart';

/// Servicio para consultar diccionarios (Local primero, luego Online)
class DictionaryService {
  final LocalDictionaryService _localDict = LocalDictionaryService();
  
  /// API Free Dictionary (Inglés)
  static const String _freeDictionaryApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  
  /// API Free Dictionary (Español)
  static const String _freeDictionaryApiEsUrl = 'https://api.dictionaryapi.dev/api/v2/entries/es';

  /// Busca la definición de una palabra en inglés
  Future<String?> lookupEnglish(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_freeDictionaryApiUrl/${word.toLowerCase()}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final meanings = data[0]['meanings'] as List<dynamic>;
          if (meanings.isNotEmpty) {
            final definitions = meanings[0]['definitions'] as List<dynamic>;
            if (definitions.isNotEmpty) {
              return definitions[0]['definition'] as String;
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error al buscar en diccionario inglés: $e');
      return null;
    }
  }

  /// Busca la definición de una palabra en español
  Future<String?> lookupSpanish(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_freeDictionaryApiEsUrl/${word.toLowerCase()}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final meanings = data[0]['meanings'] as List<dynamic>;
          if (meanings.isNotEmpty) {
            final definitions = meanings[0]['definitions'] as List<dynamic>;
            if (definitions.isNotEmpty) {
              return definitions[0]['definition'] as String;
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error al buscar en diccionario español: $e');
      return null;
    }
  }

  /// Método híbrido para obtener definición (Local -> API)
  /// Retorna 'Definición no encontrada' si falla todo.
  Future<String> getDefinition(String word) async {
    final result = await lookup(word);
    return result ?? 'Definición no encontrada';
  }

  /// Importa un diccionario desde JSON a la base de datos local
  Future<int> importDictionary(String jsonPath, {required bool isSpanishDict}) async {
    return await _localDict.importDictionary(jsonPath, isSpanishDict: isSpanishDict);
  }

  /// Busca la definición intentando primero en español y luego en inglés
  /// Mejorado con diccionario local primero, luego online
  Future<String?> lookup(String word) async {
    if (word.trim().isEmpty) return null;
    
    final cleanWord = word.trim().toLowerCase();
    
    // 1. Intentar diccionario local primero (RÁPIDO, OFFLINE)
    print('💾 Buscando en diccionario local: $cleanWord');
    try {
      final localResult = await _localDict.lookup(cleanWord);
      if (localResult != null) {
        print('✅ Encontrado en diccionario local');
        return localResult['definition'] ?? localResult['translation'];
      }
    } catch (e) {
      print('⚠️ Error en diccionario local: $e');
    }
    
    // 2. Si no está local, buscar online y guardar
    print('🌐 Diccionario local vacío, buscando online...');
    
    // Detectar si parece español
    final looksSpanish = _looksLikeSpanish(cleanWord);
    
    if (looksSpanish) {
      print('🔍 Detectado español: $cleanWord');
      
      // Intentar con la palabra original
      String? definition = await lookupSpanish(cleanWord);
      if (definition != null) return definition;
      
      // Intentar sin tildes
      final withoutAccents = _removeAccents(cleanWord);
      if (withoutAccents != cleanWord) {
        print('🔍 Reintentando sin acentos: $withoutAccents');
        definition = await lookupSpanish(withoutAccents);
        if (definition != null) return definition;
      }
    }
    
    // Intentar en inglés
    print('🔍 Buscando en inglés: $cleanWord');
    String? definition = await lookupEnglish(cleanWord);
    if (definition != null) return definition;
    
    // Último recurso: si no parecía español, intentar español
    if (!looksSpanish) {
      print('🔍 Último intento en español: $cleanWord');
      definition = await lookupSpanish(cleanWord);
    }
    
    return definition;
  }
  
  /// Detecta si una palabra parece español
  bool _looksLikeSpanish(String word) {
    // Caracteres exclusivos del español
    if (RegExp(r'[ñáéíóúü]', caseSensitive: false).hasMatch(word)) {
      return true;
    }
    
    // Terminaciones muy comunes en español
    final spanishEndings = RegExp(
      r'(ción|sión|dad|tad|miento|anza|encia|ancia|ismo|ista|ado|ido|ante|ente|ador|edor|ible|able)$',
      caseSensitive: false,
    );
    
    return spanishEndings.hasMatch(word);
  }
  
  /// Remueve acentos y caracteres especiales del español
  String _removeAccents(String str) {
    const withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutAccents = 'aeiouAEIOUnNuU';
    
    String result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Busca definiciones detalladas con múltiples significados
  Future<Map<String, dynamic>?> lookupDetailed(String word) async {
    try {
      // Intentar español primero
      var response = await http.get(
        Uri.parse('$_freeDictionaryApiEsUrl/${word.toLowerCase()}'),
      ).timeout(const Duration(seconds: 10));

      String language = 'es';
      
      // Si falla, intentar inglés
      if (response.statusCode != 200) {
        response = await http.get(
          Uri.parse('$_freeDictionaryApiUrl/${word.toLowerCase()}'),
        ).timeout(const Duration(seconds: 10));
        language = 'en';
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final entry = data[0];
          final meanings = entry['meanings'] as List<dynamic>;
          
          List<String> definitions = [];
          for (var meaning in meanings) {
            final defs = meaning['definitions'] as List<dynamic>;
            for (var def in defs) {
              definitions.add(def['definition'] as String);
            }
          }
          
          return {
            'word': word,
            'language': language,
            'definitions': definitions,
            'phonetic': entry['phonetic'] as String?,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error al buscar definición detallada: $e');
      return null;
    }
  }
}
