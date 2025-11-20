import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../bloc/biblioteca_state.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'lector_screen.dart';
import 'vocabulario_screen.dart';

/// Pantalla principal que muestra la biblioteca de libros
class BibliotecaScreen extends StatelessWidget {
  const BibliotecaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.speaker_notes),
            tooltip: 'Mi Vocabulario',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularioScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BibliotecaBloc>().add(RefreshBiblioteca());
            },
          ),
        ],
      ),
      body: BlocConsumer<BibliotecaBloc, BibliotecaState>(
        listener: (context, state) {
          if (state is BibliotecaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BibliotecaBookImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Libro "${state.book.title}" importado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BibliotecaLoading || state is BibliotecaImporting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BibliotecaLoaded) {
            if (state.books.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildBookGrid(context, state.books);
          }

          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Lógica movida al Bloc, pero aseguramos que el FilePicker solo acepte EPUB
          // Nota: El evento ImportBook del Bloc debería manejar el FilePicker.
          // Si el FilePicker está aquí en la UI (como sugería el código original del usuario), lo actualizamos.
          // Asumimos que el Bloc maneja la lógica, pero si el usuario tenía código aquí:
          /*
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['epub'],
          );
          */
          context.read<BibliotecaBloc>().add(ImportBook());
        },
        child: const Icon(Icons.add),
        tooltip: 'Importar libro (EPUB)',
      ),
    );
  }

  /// Widget para mostrar cuando no hay libros
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No hay libros en tu biblioteca',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toca el botón + para importar tu primer libro',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar la cuadrícula de libros
  Widget _buildBookGrid(BuildContext context, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(
            book: book,
            onTap: () => _openBook(context, book),
            onDelete: () => _deleteBook(context, book),
          );
        },
      ),
    );
  }

  /// Navega a la pantalla del lector
  void _openBook(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectorScreen(book: book),
      ),
    );
  }

  /// Elimina un libro de la biblioteca
  void _deleteBook(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Estás seguro de que quieres eliminar "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<BibliotecaBloc>().add(DeleteBook(book.id));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
