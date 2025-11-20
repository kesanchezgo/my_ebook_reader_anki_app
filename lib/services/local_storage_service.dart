import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

/// Servicio para gestionar el almacenamiento local de libros
class LocalStorageService {
  static const String _booksKey = 'books_list';
  static const String _progressPrefix = 'book_progress_';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Inicializa el servicio de almacenamiento local
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  /// Obtiene la lista de todos los libros guardados
  Future<List<Book>> getBooks() async {
    final String? booksJson = _prefs.getString(_booksKey);
    if (booksJson == null || booksJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> booksList = json.decode(booksJson);
      return booksList.map((bookJson) => Book.fromJson(bookJson)).toList();
    } catch (e) {
      print('Error al cargar libros: $e');
      return [];
    }
  }

  /// Guarda la lista completa de libros
  Future<bool> saveBooks(List<Book> books) async {
    try {
      final List<Map<String, dynamic>> booksJson =
          books.map((book) => book.toJson()).toList();
      final String jsonString = json.encode(booksJson);
      return await _prefs.setString(_booksKey, jsonString);
    } catch (e) {
      print('Error al guardar libros: $e');
      return false;
    }
  }

  /// Añade un nuevo libro a la biblioteca
  Future<bool> addBook(Book book) async {
    final books = await getBooks();
    books.add(book);
    return await saveBooks(books);
  }

  /// Actualiza un libro existente
  Future<bool> updateBook(Book updatedBook) async {
    final books = await getBooks();
    final index = books.indexWhere((book) => book.id == updatedBook.id);
    
    if (index != -1) {
      books[index] = updatedBook;
      return await saveBooks(books);
    }
    return false;
  }

  /// Elimina un libro de la biblioteca
  Future<bool> deleteBook(String bookId) async {
    final books = await getBooks();
    books.removeWhere((book) => book.id == bookId);
    return await saveBooks(books);
  }

  /// Guarda el progreso de lectura de un libro
  Future<bool> saveProgress(String bookId, int currentPage) async {
    return await _prefs.setInt('$_progressPrefix$bookId', currentPage);
  }

  /// Obtiene el progreso de lectura de un libro
  Future<int> getProgress(String bookId) async {
    return _prefs.getInt('$_progressPrefix$bookId') ?? 0;
  }

  /// Guarda el offset de scroll de un libro EPUB
  Future<bool> saveScrollOffset(String bookId, double offset) async {
    return await _prefs.setDouble('scroll_offset_$bookId', offset);
  }

  /// Obtiene el offset de scroll de un libro EPUB
  Future<double> getScrollOffset(String bookId) async {
    return _prefs.getDouble('scroll_offset_$bookId') ?? 0.0;
  }

  /// Limpia todos los datos guardados (para testing o reset)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
