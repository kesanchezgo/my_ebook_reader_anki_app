import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_dictionary_service.dart';
import 'settings_service.dart';

class DictionaryResult {
  final String definition;
  final String source; // 'Gemini AI', 'Diccionario Local', 'Web (FreeDictionary)', etc.

  DictionaryResult({required this.definition, required this.source});
}

/// Servicio para consultar diccionarios (Local, Web, Gemini)
class DictionaryService {
  final LocalDictionaryService _localDict = LocalDictionaryService();
  
  /// API Free Dictionary (Inglés)
  static const String _freeDictionaryApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  
  /// API Free Dictionary (Español)
  static const String _freeDictionaryApiEsUrl = 'https://api.dictionaryapi.dev/api/v2/entries/es';

  /// Busca la definición de una palabra en inglés
  Future<DictionaryResult?> lookupEnglish(String word) async {
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
              return DictionaryResult(
                definition: definitions[0]['definition'] as String,
                source: 'Web (English)',
              );
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
  Future<DictionaryResult?> lookupSpanish(String word) async {
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
              return DictionaryResult(
                definition: definitions[0]['definition'] as String,
                source: 'Web (Español)',
              );
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

  /// Método principal para obtener definición usando la prioridad configurada
  Future<DictionaryResult> getDefinition(String word) async {
    if (word.trim().isEmpty) {
      return DictionaryResult(definition: 'Palabra vacía', source: 'Sistema');
    }

    final cleanWord = word.trim().toLowerCase();
    final priorities = SettingsService.instance.dictionaryPriority;

    for (final source in priorities) {
      DictionaryResult? result;
      
      switch (source) {
        case 'gemini':
          result = await _lookupGemini(cleanWord);
          break;
        case 'local':
          result = await _lookupLocal(cleanWord);
          break;
        case 'web':
          result = await _lookupWeb(cleanWord);
          break;
      }

      if (result != null) {
        return result;
      }
    }

    return DictionaryResult(
      definition: 'Definición no encontrada en ninguna fuente.',
      source: 'Sistema',
    );
  }

  Future<DictionaryResult?> _lookupLocal(String word) async {
    print('💾 Buscando en diccionario local: $word');
    try {
      final localResult = await _localDict.lookup(word);
      if (localResult != null) {
        print('✅ Encontrado en diccionario local');
        return DictionaryResult(
          definition: localResult['definition'] ?? localResult['translation'],
          source: 'Diccionario Local',
        );
      }
    } catch (e) {
      print('⚠️ Error en diccionario local: $e');
    }
    return null;
  }

  Future<DictionaryResult?> _lookupWeb(String word) async {
    print('🌐 Buscando en Web...');
    
    // Detectar si parece español
    final looksSpanish = _looksLikeSpanish(word);
    
    if (looksSpanish) {
      print('🔍 Detectado español: $word');
      
      // Intentar con la palabra original
      var result = await lookupSpanish(word);
      if (result != null) return result;
      
      // Intentar sin tildes
      final withoutAccents = _removeAccents(word);
      if (withoutAccents != word) {
        print('🔍 Reintentando sin acentos: $withoutAccents');
        result = await lookupSpanish(withoutAccents);
        if (result != null) return result;
      }
    }
    
    // Intentar en inglés
    print('🔍 Buscando en inglés: $word');
    var result = await lookupEnglish(word);
    if (result != null) return result;
    
    // Último recurso: si no parecía español, intentar español
    if (!looksSpanish) {
      print('🔍 Último intento en español: $word');
      result = await lookupSpanish(word);
      if (result != null) return result;
    }
    
    return null;
  }

  Future<DictionaryResult?> _lookupGemini(String word) async {
    final apiKey = SettingsService.instance.geminiApiKey;
    if (apiKey.isEmpty) return null;

    print('🤖 Buscando en Gemini AI: $word');
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "Define brevemente la palabra '$word' en español. Si tiene múltiples acepciones, da la más común. Máximo 40 palabras."
            }]
          }]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null) {
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              final text = parts[0]['text'] as String;
              return DictionaryResult(
                definition: text.trim(),
                source: 'Gemini AI',
              );
            }
          }
        }
      } else {
        print('Error Gemini API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error consultando Gemini: $e');
    }
    return null;
  }

  /// Importa un diccionario desde JSON a la base de datos local
  Future<int> importDictionary(String jsonPath, {required bool isSpanishDict}) async {
    return await _localDict.importDictionary(jsonPath, isSpanishDict: isSpanishDict);
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
