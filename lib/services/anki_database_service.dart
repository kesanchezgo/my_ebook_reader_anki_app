import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/anki_card.dart';

/// Servicio para gestionar la base de datos SQLite de tarjetas Anki
class AnkiDatabaseService {
  static const String _databaseName = 'anki_cards.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'anki_cards';

  Database? _database;

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        definition TEXT NOT NULL,
        contexto TEXT NOT NULL,
        example TEXT DEFAULT "",
        fuente TEXT NOT NULL,
        audioPath TEXT,
        bookId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        reviewCount INTEGER DEFAULT 0,
        lastReviewedAt TEXT
      )
    ''');

    // Crear índice para búsqueda rápida por libro
    await db.execute('''
      CREATE INDEX idx_book_id ON $_tableName (bookId)
    ''');
  }

  /// Actualiza la base de datos si cambia la versión
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración simple: renombrar columnas si es posible o recrear tabla
      // SQLite no soporta renombrar columnas fácilmente en versiones antiguas,
      // pero podemos añadir las nuevas y copiar datos si fuera necesario.
      // Para este caso, asumiremos que podemos alterar la tabla o que es aceptable perder datos en desarrollo.
      // Pero para ser seguros, añadimos las columnas nuevas.
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN contexto TEXT DEFAULT ""');
        await db.execute('ALTER TABLE $_tableName ADD COLUMN fuente TEXT DEFAULT ""');
        // Copiar datos antiguos si existen
        // No se realiza UPDATE porque las columnas 'sentence' y 'bookTitle' no existen en el esquema actual.
      } catch (e) {
        // Si falla (ej. columnas ya existen), ignorar
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN example TEXT DEFAULT ""');
      } catch (e) {
        print('Error adding example column: $e');
      }
    }
  }

  /// Inserta una nueva tarjeta
  Future<void> insertCard(AnkiCard card) async {
    final db = await database;
    await db.insert(
      _tableName,
      card.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Verifica si una palabra ya existe en el vocabulario del libro actual
  Future<bool> wordExistsInBook(String word, String bookId) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'LOWER(word) = ? AND bookId = ?',
      whereArgs: [word.toLowerCase(), bookId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Obtiene todas las tarjetas
  Future<List<AnkiCard>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => AnkiCard.fromJson(maps[i]));
  }

  /// Obtiene tarjetas de un libro específico
  Future<List<AnkiCard>> getCardsByBook(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => AnkiCard.fromJson(maps[i]));
  }

  /// Busca tarjetas por palabra
  Future<List<AnkiCard>> searchCards(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'word LIKE ? OR contexto LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => AnkiCard.fromJson(maps[i]));
  }

  /// Actualiza una tarjeta
  Future<void> updateCard(AnkiCard card) async {
    final db = await database;
    await db.update(
      _tableName,
      card.toJson(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Elimina una tarjeta
  Future<void> deleteCard(String cardId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Obtiene el número total de tarjetas
  Future<int> getCardCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene el número de tarjetas de un libro
  Future<int> getCardCountByBook(String bookId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE bookId = ?',
      [bookId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
