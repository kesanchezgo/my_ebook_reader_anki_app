import 'package:equatable/equatable.dart';
import '../models/book.dart';

/// Estados posibles de la Biblioteca
abstract class BibliotecaState extends Equatable {
  const BibliotecaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class BibliotecaInitial extends BibliotecaState {}

/// Estado de carga
class BibliotecaLoading extends BibliotecaState {}

/// Estado cuando los libros se han cargado exitosamente
class BibliotecaLoaded extends BibliotecaState {
  final List<Book> books;

  const BibliotecaLoaded(this.books);

  @override
  List<Object?> get props => [books];
}

/// Estado de error
class BibliotecaError extends BibliotecaState {
  final String message;

  const BibliotecaError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado cuando se está importando un libro
class BibliotecaImporting extends BibliotecaState {}

/// Estado cuando un libro se ha importado exitosamente
class BibliotecaBookImported extends BibliotecaState {
  final Book book;

  const BibliotecaBookImported(this.book);

  @override
  List<Object?> get props => [book];
}
