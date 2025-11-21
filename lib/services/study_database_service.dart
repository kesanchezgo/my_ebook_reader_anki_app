import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/study_card.dart';

/// Servicio para gestionar la base de datos SQLite de tarjetas de estudio
class StudyDatabaseService {
  // static const String _databaseName = 'study_cards.db'; // Renamed DB file for clarity, or keep old one? Better keep old one to avoid losing data if user updates app.
  // Actually, if I change the DB name, it will create a new empty DB.
  // I should keep the old filename 'anki_cards.db' but change the class and table logic.
  // OR, I can migrate the file.
  // Let's keep the filename 'anki_cards.db' to preserve user data.
  static const String _databaseNameFile = 'anki_cards.db'; 
  static const int _databaseVersion = 4; // Bump version
  static const String _tableName = 'study_cards'; // New table name

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
    final path = join(dbPath, _databaseNameFile);

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
        type TEXT DEFAULT 'StudyCardType.enrichment',
        content TEXT,
        definition TEXT, -- Deprecated, kept for legacy compatibility if needed
        contexto TEXT, -- Deprecated
        example TEXT, -- Deprecated
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
      try {
        await db.execute('ALTER TABLE anki_cards ADD COLUMN contexto TEXT DEFAULT ""');
        await db.execute('ALTER TABLE anki_cards ADD COLUMN fuente TEXT DEFAULT ""');
      } catch (e) {
        // Ignorar si ya existen
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE anki_cards ADD COLUMN example TEXT DEFAULT ""');
      } catch (e) {
        print('Error adding example column: $e');
      }
    }

    if (oldVersion < 4) {
      // Migración a StudyCard
      try {
        // 1. Renombrar tabla
        await db.execute('ALTER TABLE anki_cards RENAME TO study_cards');
      } catch (e) {
        print('Error renaming table (might already be renamed): $e');
      }

      try {
        // 2. Añadir nuevas columnas
        await db.execute('ALTER TABLE study_cards ADD COLUMN type TEXT DEFAULT "StudyCardType.enrichment"');
        await db.execute('ALTER TABLE study_cards ADD COLUMN content TEXT'); // Nullable
      } catch (e) {
        print('Error adding new columns: $e');
      }
    }
  }

  /// Inserta una nueva tarjeta
  Future<void> insertCard(StudyCard card) async {
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
  Future<List<StudyCard>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => StudyCard.fromJson(maps[i]));
  }

  /// Obtiene tarjetas de un libro específico
  Future<List<StudyCard>> getCardsByBook(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => StudyCard.fromJson(maps[i]));
  }

  /// Busca tarjetas por palabra
  Future<List<StudyCard>> searchCards(String query) async {
    final db = await database;
    // Nota: La búsqueda por 'contexto' ahora depende de si está en la columna antigua o en el JSON.
    // Para simplificar, asumimos que 'word' sigue siendo columna.
    // Si queremos buscar en JSON, SQLite tiene funciones JSON pero depende de la versión.
    // Por ahora mantenemos la búsqueda simple en columnas legacy si existen, o solo word.
    
    // Estrategia híbrida: buscar en columnas legacy (si existen datos) O en word.
    // Si el contenido está en JSON, la búsqueda SQL simple no funcionará para definition/context.
    // Solución ideal: FTS (Full Text Search) o mover datos clave a columnas.
    // Dado que mantenemos 'word' como columna, la búsqueda por palabra funciona.
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'word LIKE ?', // Simplificado por seguridad en migración
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => StudyCard.fromJson(maps[i]));
  }

  /// Actualiza una tarjeta
  Future<void> updateCard(StudyCard card) async {
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
