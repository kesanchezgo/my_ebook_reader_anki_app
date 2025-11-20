import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book.dart';
import '../services/local_storage_service.dart';
import '../services/file_service.dart';
import '../services/epub_service.dart';
import 'biblioteca_event.dart';
import 'biblioteca_state.dart';
import 'dart:io';

/// Bloc para gestionar el estado de la Biblioteca
class BibliotecaBloc extends Bloc<BibliotecaEvent, BibliotecaState> {
  final LocalStorageService _storageService;
  final FileService _fileService;
  final EpubService _epubService = EpubService();

  BibliotecaBloc({
    required LocalStorageService storageService,
    required FileService fileService,
  })  : _storageService = storageService,
        _fileService = fileService,
        super(BibliotecaInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<ImportBook>(_onImportBook);
    on<DeleteBook>(_onDeleteBook);
    on<UpdateBook>(_onUpdateBook);
    on<RefreshBiblioteca>(_onRefreshBiblioteca);
  }

  /// Carga la lista de libros guardados
  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BibliotecaState> emit,
  ) async {
    emit(BibliotecaLoading());
    try {
      final books = await _storageService.getBooks();
      emit(BibliotecaLoaded(books));
    } catch (e) {
      emit(BibliotecaError('Error al cargar los libros: $e'));
    }
  }

  /// Importa un nuevo libro
  Future<void> _onImportBook(
    ImportBook event,
    Emitter<BibliotecaState> emit,
  ) async {
    try {
      emit(BibliotecaImporting());

      // Abrir selector de archivos
      final result = await _fileService.pickBookFile();

      if (result == null || result.files.isEmpty) {
        // Usuario canceló la selección
        final books = await _storageService.getBooks();
        emit(BibliotecaLoaded(books));
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        emit(const BibliotecaError('No se pudo acceder al archivo'));
        return;
      }

      // Copiar archivo al directorio de la app
      final fileName = _fileService.getFileName(file.path!);
      final newPath = await _fileService.copyFileToAppDirectory(
        file.path!,
        fileName,
      );

      if (newPath == null) {
        emit(const BibliotecaError('Error al copiar el archivo'));
        return;
      }

      // Crear el objeto Book usando EpubService para metadatos y validación
      Book book;
      try {
        book = await _epubService.loadBookInfo(File(newPath));
      } catch (e) {
        // Si falla (ej. duplicado), borramos el archivo copiado
        await _fileService.deleteFile(newPath);
        if (e is DuplicateBookException) {
          emit(BibliotecaError(e.message));
        } else {
          emit(BibliotecaError('Error al procesar el libro: $e'));
        }
        // Recargar lista para quitar estado de carga
        final books = await _storageService.getBooks();
        emit(BibliotecaLoaded(books));
        return;
      }

      // Guardar en la base de datos local
      final success = await _storageService.addBook(book);

      if (success) {
        emit(BibliotecaBookImported(book));
        // Recargar la lista de libros
        final books = await _storageService.getBooks();
        emit(BibliotecaLoaded(books));
      } else {
        emit(const BibliotecaError('Error al guardar el libro'));
      }
    } catch (e) {
      emit(BibliotecaError('Error al importar el libro: $e'));
    }
  }

  /// Elimina un libro
  Future<void> _onDeleteBook(
    DeleteBook event,
    Emitter<BibliotecaState> emit,
  ) async {
    try {
      emit(BibliotecaLoading());

      // Obtener el libro para eliminar el archivo
      final books = await _storageService.getBooks();
      final book = books.firstWhere((b) => b.id == event.bookId);

      // Eliminar el archivo físico
      await _fileService.deleteFile(book.filePath);

      // Eliminar de la base de datos
      await _storageService.deleteBook(event.bookId);

      // Recargar la lista
      final updatedBooks = await _storageService.getBooks();
      emit(BibliotecaLoaded(updatedBooks));
    } catch (e) {
      emit(BibliotecaError('Error al eliminar el libro: $e'));
    }
  }

  /// Actualiza un libro (por ejemplo, su progreso)
  Future<void> _onUpdateBook(
    UpdateBook event,
    Emitter<BibliotecaState> emit,
  ) async {
    try {
      await _storageService.updateBook(event.book);
      
      // Recargar la lista
      final books = await _storageService.getBooks();
      emit(BibliotecaLoaded(books));
    } catch (e) {
      emit(BibliotecaError('Error al actualizar el libro: $e'));
    }
  }

  /// Refresca la biblioteca
  Future<void> _onRefreshBiblioteca(
    RefreshBiblioteca event,
    Emitter<BibliotecaState> emit,
  ) async {
    try {
      final books = await _storageService.getBooks();
      emit(BibliotecaLoaded(books));
    } catch (e) {
      emit(BibliotecaError('Error al refrescar la biblioteca: $e'));
    }
  }
}
