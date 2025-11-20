import 'package:equatable/equatable.dart';
import '../models/book.dart';

/// Eventos de la Biblioteca
abstract class BibliotecaEvent extends Equatable {
  const BibliotecaEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los libros
class LoadBooks extends BibliotecaEvent {}

/// Evento para importar un nuevo libro
class ImportBook extends BibliotecaEvent {}

/// Evento para eliminar un libro
class DeleteBook extends BibliotecaEvent {
  final String bookId;

  const DeleteBook(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

/// Evento para actualizar un libro
class UpdateBook extends BibliotecaEvent {
  final Book book;

  const UpdateBook(this.book);

  @override
  List<Object?> get props => [book];
}

/// Evento para refrescar la biblioteca
class RefreshBiblioteca extends BibliotecaEvent {}
