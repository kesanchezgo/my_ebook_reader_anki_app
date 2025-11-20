import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'local_dictionary_service.dart';
import 'settings_service.dart';

class DictionaryResult {
  final String definition;
  final String? example;
  final String source; // 'Gemini AI', 'Diccionario Local', 'Web (FreeDictionary)', etc.

  DictionaryResult({
    required this.definition, 
    this.example,
    required this.source,
  });
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
                example: definitions[0]['example'] as String?,
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
                example: definitions[0]['example'] as String?,
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
          example: localResult['examples'],
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
              "text": "Define la palabra '$word' en español con estilo de diccionario. La definición debe tener entre 10 y 25 palabras, ser objetiva y precisa. Luego incluye un ejemplo de uso de entre 8 y 15 palabras. Responde SOLO con un objeto JSON con las claves 'definition' y 'example'."
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
              // Limpiar markdown si existe (```json ... ```)
              final cleanJson = text.replaceAll(RegExp(r'```json|```'), '').trim();
              
              try {
                final jsonResponse = jsonDecode(cleanJson);
                return DictionaryResult(
                  definition: jsonResponse['definition'] ?? text,
                  example: jsonResponse['example'],
                  source: 'Gemini AI',
                );
              } catch (e) {
                // Fallback si no es JSON válido
                return DictionaryResult(
                  definition: text.trim(),
                  source: 'Gemini AI',
                );
              }
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

  /// Explica un contexto usando IA (Gemini o Perplexity según prioridad)
  Future<Map<String, dynamic>?> explainContext(String context) async {
    final priorities = SettingsService.instance.contextPriority;

    for (final source in priorities) {
      Map<String, dynamic>? result;
      
      switch (source) {
        case 'gemini':
          result = await _explainContextGemini(context);
          break;
        case 'perplexity':
          result = await _explainContextPerplexity(context);
          break;
      }

      if (result != null) {
        // Añadir la fuente al resultado para mostrar en UI
        result['source'] = source == 'gemini' ? 'Gemini AI' : 'Perplexity AI';
        return result;
      }
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> _explainContextGemini(String context) async {
    final apiKey = SettingsService.instance.geminiApiKey;
    if (apiKey.isEmpty) return null;

    print('🤖 Explicando contexto con Gemini AI...');
    try {
      // Usamos gemini-1.5-flash que es la versión estable y rápida actual.
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": """
Analiza el siguiente texto en español y genera una explicación didáctica en formato JSON.
El objetivo es ayudar a un estudiante a comprender el contexto, el vocabulario y el sentido del texto.

Devuelve SOLO un objeto JSON con esta estructura exacta:
{
  "main_idea": "Explicación clara y concisa de la idea principal del texto (máx 2 frases).",
  "complex_terms": [
    {
      "term": "Palabra o frase difícil",
      "explanation": "Significado sencillo en este contexto."
    }
  ],
  "usage_examples": [
    "Un ejemplo de uso similar o una frase reescrita de forma más sencilla."
  ],
  "cultural_note": "Opcional: Si hay alguna referencia cultural, idiomática o tono específico (irónico, formal, etc.), menciónalo aquí. Si no, null."
}

Texto a analizar: "$context"
"""
            }]
          }]
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null) {
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              final text = parts[0]['text'] as String;
              // Limpiar markdown si existe (```json ... ```)
              final cleanJson = text.replaceAll(RegExp(r'```json|```'), '').trim();
              try {
                return jsonDecode(cleanJson) as Map<String, dynamic>;
              } catch (e) {
                print('Error parsing JSON from Gemini: $e');
              }
            }
          }
        }
      } else {
        print('Error Gemini API: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException catch (_) {
      print('⏱️ Error: La solicitud a Gemini excedió el tiempo de espera (40s). Verifica tu conexión.');
    } on SocketException catch (_) {
      print('📡 Error: No hay conexión a internet o el servidor no es accesible.');
    } catch (e) {
      print('Error consultando Gemini para explicación: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _explainContextPerplexity(String context) async {
    final apiKey = SettingsService.instance.perplexityApiKey.trim();
    if (apiKey.isEmpty) return null;

    // Debug: Mostrar primeros caracteres para verificar que la key se lee bien
    final maskedKey = apiKey.length > 10 ? '${apiKey.substring(0, 8)}...' : '***';
    print('🧠 Explicando contexto con Perplexity AI (Key: $maskedKey)...');

    try {
      final url = Uri.parse('https://api.perplexity.ai/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "sonar",
          "messages": [
            {
              "role": "system",
              "content": "Eres un tutor de español que ayuda a estudiantes a comprender textos complejos mediante análisis didáctico."
            },
            {
              "role": "user",
              "content": "Analiza el siguiente texto en español: \"$context\""
            }
          ],
          "response_format": {
            "type": "json_schema",
            "json_schema": {
              "schema": {
                "type": "object",
                "properties": {
                  "main_idea": {
                    "type": "string",
                    "description": "Explicación clara y concisa de la idea principal del texto (máximo 2 frases)."
                  },
                  "complex_terms": {
                    "type": "array",
                    "description": "Lista de palabras o frases difíciles del texto con sus explicaciones.",
                    "items": {
                      "type": "object",
                      "properties": {
                        "term": {
                          "type": "string",
                          "description": "Palabra o frase difícil extraída del texto."
                        },
                        "explanation": {
                          "type": "string",
                          "description": "Significado sencillo de la palabra o frase en este contexto específico."
                        }
                      },
                      "required": ["term", "explanation"],
                      "additionalProperties": false
                    }
                  },
                  "usage_examples": {
                    "type": "array",
                    "description": "Ejemplos de uso similar o frases reescritas de forma más sencilla para facilitar la comprensión.",
                    "items": {
                      "type": "string",
                      "description": "Un ejemplo de uso similar o una frase del texto reescrita de forma más sencilla."
                    }
                  },
                  "cultural_note": {
                    "type": ["string", "null"],
                    "description": "Opcional: Si hay alguna referencia cultural, idiomática o tono específico (irónico, formal, etc.), menciónalo aquí. Si no hay ninguna referencia cultural relevante, devuelve null."
                  }
                },
                "required": ["main_idea", "complex_terms", "usage_examples", "cultural_note"],
                "additionalProperties": false
              }
            }
          },
          "max_tokens": 1000,
          "temperature": 0.2
        }),
      ).timeout(const Duration(seconds: 40));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && (data['choices'] as List).isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          if (content != null) {
            try {
              // Perplexity devuelve el JSON como string dentro de content
              return jsonDecode(content) as Map<String, dynamic>;
            } catch (e) {
              print('Error parsing JSON from Perplexity: $e');
            }
          }
        }
      } else {
        print('Error Perplexity API: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException catch (_) {
      print('⏱️ Error: La solicitud a Perplexity excedió el tiempo de espera (40s).');
    } catch (e) {
      print('Error consultando Perplexity para explicación: $e');
    }
    return null;
  }
}
