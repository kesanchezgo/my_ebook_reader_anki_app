import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio profesional de diccionarios monolingües con almacenamiento local
/// Diccionario monolingüe: palabra y definición en el mismo idioma
/// Prioridad: Local → Online → Error
class LocalDictionaryService {
  static Database? _database;
  static const String _dbName = 'dictionaries.db';
  static const String _tableDictEs = 'dict_es'; // Diccionario español (palabra ES → definición ES)
  static const String _tableDictEn = 'dict_en'; // Diccionario inglés (palabra EN → definición EN)
  
  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: 2, // Incrementar versión para migración
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// Crea las tablas iniciales
  Future<void> _onCreate(Database db, int version) async {
    // Crear tabla para diccionario español monolingüe
    await db.execute('''
      CREATE TABLE $_tableDictEs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL UNIQUE,
        definition TEXT NOT NULL,
        examples TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX idx_es_word ON $_tableDictEs(word)');
    
    // Crear tabla para diccionario inglés monolingüe
    await db.execute('''
      CREATE TABLE $_tableDictEn (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL UNIQUE,
        definition TEXT NOT NULL,
        examples TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX idx_en_word ON $_tableDictEn(word)');
  }
  
  /// Migra de versión antigua a nueva
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrar de dict_es_en/dict_en_es a dict_es/dict_en
      try {
        // Intentar copiar datos de tablas antiguas si existen
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('dict_es_en', 'dict_en_es')"
        );
        
        if (tables.isNotEmpty) {
          // Crear nuevas tablas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_tableDictEs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL UNIQUE,
              definition TEXT NOT NULL,
              examples TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_tableDictEn (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL UNIQUE,
              definition TEXT NOT NULL,
              examples TEXT
            )
          ''');
          
          // Copiar datos de dict_es_en a dict_es
          await db.execute('''
            INSERT OR IGNORE INTO $_tableDictEs (word, definition, examples)
            SELECT word, COALESCE(definition, translation), examples
            FROM dict_es_en
          ''');
          
          // Copiar datos de dict_en_es a dict_en
          await db.execute('''
            INSERT OR IGNORE INTO $_tableDictEn (word, definition, examples)
            SELECT word, COALESCE(definition, translation), examples
            FROM dict_en_es
          ''');
          
          // Eliminar tablas antiguas
          await db.execute('DROP TABLE IF EXISTS dict_es_en');
          await db.execute('DROP TABLE IF EXISTS dict_en_es');
          
          print('✓ Migración completada: diccionarios convertidos a monolingües');
        } else {
          // No hay datos antiguos, crear tablas nuevas
          await _onCreate(db, newVersion);
        }
        
        // Crear índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_es_word ON $_tableDictEs(word)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_en_word ON $_tableDictEn(word)');
      } catch (e) {
        print('⚠️ Error en migración: $e');
        // Si falla, crear tablas limpias
        await _onCreate(db, newVersion);
      }
    }
  }
  
  /// Busca una palabra en el diccionario local primero, luego online
  /// [sourceLang] debe ser 'es' o 'en' para especificar el idioma del diccionario
  Future<Map<String, dynamic>?> lookup(String word, {String? sourceLang}) async {
    try {
      // 1. Determinar orden de búsqueda
      // Si se especifica idioma, buscar solo en ese.
      // Si no, intentar adivinar, pero buscar en AMBOS si falla.
      final primaryLang = sourceLang ?? (_looksLikeSpanish(word) ? 'es' : 'en');
      final secondaryLang = (sourceLang == null) ? (primaryLang == 'es' ? 'en' : 'es') : null;
      
      // 2. Buscar en diccionario local (Idioma primario)
      var localResult = await _lookupLocal(word, sourceLang: primaryLang);
      if (localResult != null) {
        print('📖 Palabra encontrada en diccionario $primaryLang local: $word');
        return localResult;
      }
      
      // 3. Si no se encuentra y hay idioma secundario, buscar en el otro
      if (secondaryLang != null) {
        localResult = await _lookupLocal(word, sourceLang: secondaryLang);
        if (localResult != null) {
          print('📖 Palabra encontrada en diccionario $secondaryLang local (fallback): $word');
          return localResult;
        }
      }
      
      // 4. Si no está local, buscar online (solo en el idioma primario o el especificado)
      // Nota: Podríamos intentar online en ambos, pero sería lento. Nos quedamos con la mejor adivinanza.
      print('🌐 Buscando online: $word ($primaryLang)');
      final onlineResult = await _lookupOnline(word, sourceLang: primaryLang);
      
      // 5. Si se encuentra online, guardar en local
      if (onlineResult != null) {
        await _saveToLocal(onlineResult, sourceLang: primaryLang);
        return onlineResult;
      }
      
      // Intento online secundario si falló el primario y no se especificó idioma
      if (onlineResult == null && secondaryLang != null) {
         print('🌐 Buscando online (fallback): $word ($secondaryLang)');
         final onlineResultSec = await _lookupOnline(word, sourceLang: secondaryLang);
         if (onlineResultSec != null) {
            await _saveToLocal(onlineResultSec, sourceLang: secondaryLang);
            return onlineResultSec;
         }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error en lookup: $e');
      return null;
    }
  }
  
  /// Busca en la base de datos local (diccionario monolingüe)
  Future<Map<String, dynamic>?> _lookupLocal(String word, {String? sourceLang}) async {
    try {
      final db = await database;
      final isSpanish = sourceLang == 'es';
      final table = isSpanish ? _tableDictEs : _tableDictEn;
      
      // Buscar palabra exacta
      var results = await db.query(
        table,
        where: 'word = ?',
        whereArgs: [word.toLowerCase()],
        limit: 1,
      );
      
      // Si no encuentra y es español, intentar sin acentos
      if (results.isEmpty && isSpanish) {
        final wordNoAccents = _removeAccents(word.toLowerCase());
        results = await db.query(
          table,
          where: 'word = ?',
          whereArgs: [wordNoAccents],
          limit: 1,
        );
      }
      
      if (results.isNotEmpty) {
        return {
          'word': results.first['word'] as String,
          'translation': results.first['definition'] as String, // Mantener 'translation' para compatibilidad
          'definition': results.first['definition'] as String,
          'examples': results.first['examples'] as String?,
          'source': 'local',
        };
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error buscando en local: $e');
      return null;
    }
  }
  
  /// Busca online en la API de diccionarios
  Future<Map<String, dynamic>?> _lookupOnline(String word, {String? sourceLang}) async {
    try {
      final isSpanish = sourceLang == 'es' || _looksLikeSpanish(word);
      final apiUrl = isSpanish
          ? 'https://api.dictionaryapi.dev/api/v2/entries/es/$word'
          : 'https://api.dictionaryapi.dev/api/v2/entries/en/$word';
      
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final meanings = data[0]['meanings'] as List<dynamic>;
          if (meanings.isNotEmpty) {
            final definitions = meanings[0]['definitions'] as List<dynamic>;
            if (definitions.isNotEmpty) {
              final definition = definitions[0]['definition'] as String;
              
              return {
                'word': word,
                'translation': definition, // Mantener para compatibilidad
                'definition': definition,
                'examples': definitions[0]['example'] ?? '',
                'source': 'online',
              };
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error en búsqueda online: $e');
      return null;
    }
  }
  
  /// Guarda un resultado online en el diccionario local
  Future<void> _saveToLocal(Map<String, dynamic> data, {String? sourceLang}) async {
    try {
      final db = await database;
      final isSpanish = sourceLang == 'es';
      final table = isSpanish ? _tableDictEs : _tableDictEn;
      
      await db.insert(
        table,
        {
          'word': data['word'],
          'definition': data['definition'] ?? data['translation'] ?? '',
          'examples': data['examples'] ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('💾 Palabra guardada en diccionario ${isSpanish ? "ES" : "EN"} local: ${data["word"]}');
    } catch (e) {
      print('⚠️ Error guardando en local: $e');
    }
  }
  
  /// Importa un diccionario monolingüe desde un archivo JSON
  /// 
  /// Formato esperado: [{"id": "...", "lemma": "palabra", "definition": "significado..."}]
  /// También soporta formatos flexibles.
  /// 
  /// [jsonPath] ruta al archivo JSON
  /// [isSpanishDict] true = diccionario español, false = diccionario inglés
  /// 
  /// Retorna el número de entradas importadas exitosamente
  Future<int> importDictionary(String jsonPath, {required bool isSpanishDict}) async {
    try {
      print('📥 Importando diccionario ${isSpanishDict ? "ES" : "EN"} desde: $jsonPath');
      
      final file = File(jsonPath);
      if (!await file.exists()) {
        throw Exception('El archivo no existe');
      }

      final jsonString = await file.readAsString();
      
      // Intentar decodificar JSON
      dynamic data;
      try {
        data = json.decode(jsonString);
      } catch (e) {
        throw Exception('Archivo no es JSON válido: $e');
      }

      // Validar que sea un array
      if (data is! List) {
        throw Exception('Formato incorrecto: se esperaba un array JSON');
      }

      if (data.isEmpty) {
        throw Exception('El archivo no contiene entradas');
      }

      final db = await database;
      final table = isSpanishDict ? _tableDictEs : _tableDictEn;
      
      int importedCount = 0;
      int skippedCount = 0;
      
      // Usar Batch para inserción masiva (mucho más rápido)
      final batch = db.batch();
      
      // Procesar cada entrada
      for (var entry in data) {
        if (entry is! Map) {
          skippedCount++;
          continue;
        }

        // Flexible field extraction - probar múltiples nombres
        // Prioridad: lemma (según solicitud del usuario)
        final word = _extractField(entry, ['lemma', 'word', 'term', 'headword', 'entrada']);
        final definition = _extractField(entry, ['definition', 'meaning', 'def', 'definicion', 'description']);
        final examples = _extractField(entry, ['examples', 'example', 'sentences', 'ejemplos']);

        // Validar campos requeridos (palabra y definición)
        if (word == null || word.isEmpty || definition == null || definition.isEmpty) {
          skippedCount++;
          continue;
        }

        // Insertar en batch
        // ConflictAlgorithm.ignore: Si el lemma ya existe, se ignora esta entrada.
        batch.insert(
          table,
          {
            'word': word.trim().toLowerCase(),
            'definition': definition.trim(),
            'examples': examples?.trim(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore, 
        );
        importedCount++;
      }

      // Ejecutar el batch
      await batch.commit(noResult: true);

      print('✓ Diccionario importado: $importedCount entradas procesadas ($skippedCount omitidas)');
      
      if (importedCount == 0) {
        throw Exception('No se pudo importar ninguna entrada válida. Verifique el formato del archivo.');
      }

      return importedCount;
    } catch (e) {
      print('❌ Error al importar diccionario: $e');
      rethrow;
    }
  }

  /// Método híbrido para obtener definición: Local -> API
  Future<String> getDefinition(String word) async {
    // Paso 1: Buscar en local
    final localResult = await lookup(word);
    if (localResult != null) {
      return localResult['definition'] ?? localResult['translation'] ?? 'Definición no encontrada';
    }
    
    // Paso 2: Buscar online (lookup ya hace esto internamente si no encuentra en local, 
    // pero aquí lo explicitamos para cumplir con el flujo solicitado si lookup cambiara)
    // En este caso, lookup ya implementa la lógica híbrida completa.
    // Si lookup retorna null, es que falló todo.
    
    return 'Definición no encontrada';
  }

  /// Extrae un campo de un Map intentando múltiples nombres
  String? _extractField(Map entry, List<String> possibleNames) {
    for (var name in possibleNames) {
      final value = entry[name];
      if (value != null) {
        if (value is String) return value;
        if (value is List) return value.join('; '); // Arrays → string separado por ;
        return value.toString();
      }
    }
    return null;
  }
  
  /// Detecta si una palabra parece español
  bool _looksLikeSpanish(String word) {
    if (RegExp(r'[ñáéíóúü]', caseSensitive: false).hasMatch(word)) {
      return true;
    }
    
    final spanishEndings = RegExp(
      r'(ción|sión|dad|tad|miento|anza|encia|ancia|ismo|ista|ado|ido|ante|ente|ador|edor)$',
      caseSensitive: false,
    );
    
    return spanishEndings.hasMatch(word);
  }
  
  /// Remueve acentos
  String _removeAccents(String str) {
    const accents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const noAccents = 'aeiouAEIOUnNuU';
    
    String result = str;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }
    return result;
  }
  
  /// Obtiene estadísticas del diccionario local
  Future<Map<String, int>> getStats() async {
    try {
      final db = await database;
      
      final esCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableDictEs'),
      ) ?? 0;
      
      final enCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableDictEn'),
      ) ?? 0;
      
      return {
        'spanish': esCount,
        'english': enCount,
        'total': esCount + enCount,
      };
    } catch (e) {
      return {'spanish': 0, 'english': 0, 'total': 0};
    }
  }
  
  /// Limpia el diccionario local
  Future<void> clearDictionary() async {
    final db = await database;
    await db.delete(_tableDictEs);
    await db.delete(_tableDictEn);
    print('🗑️ Diccionario local limpiado');
  }
  
  /// Obtiene el tamaño de la base de datos en MB
  Future<double> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, _dbName);
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        final sizeInBytes = await dbFile.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);
        print('📊 Tamaño de base de datos: ${sizeInMB.toStringAsFixed(2)} MB');
        return sizeInMB;
      }
      return 0.0;
    } catch (e) {
      print('⚠️ Error obteniendo tamaño: $e');
      return 0.0;
    }
  }
}
