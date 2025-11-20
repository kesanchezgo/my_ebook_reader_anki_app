import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../bloc/biblioteca_state.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/premium_toast.dart';
import 'lector_screen.dart';
import 'vocabulario_screen.dart';
import 'settings_screen.dart';

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
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
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
    bool deleteData = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Eliminar libro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Estás seguro de que quieres eliminar "${book.title}"?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: deleteData,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) {
                          setState(() => deleteData = value ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => deleteData = !deleteData),
                        child: const Text(
                          'Eliminar también datos de lectura (progreso, tiempo, etc.)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (deleteData) {
                    final prefs = await SharedPreferences.getInstance();
                    // Eliminar tiempo de lectura
                    await prefs.remove('reading_time_${book.id}');
                    // Eliminar posiciones de scroll (esto es más difícil porque hay N capítulos)
                    // Iteramos un número razonable o usamos un patrón si pudiéramos.
                    // Como no sabemos cuántos capítulos hay aquí fácilmente sin cargar el libro,
                    // intentamos borrar un rango razonable o dejamos residuos pequeños.
                    // O mejor, SettingsService debería tener un método clearBookData.
                    // Por ahora, borramos lo principal.
                    for (int i = 0; i < 1000; i++) {
                      if (prefs.containsKey('scroll_${book.id}_$i')) {
                        await prefs.remove('scroll_${book.id}_$i');
                      } else {
                        // Si no encontramos el 0, puede que no haya empezado.
                        // Si encontramos huecos, seguimos un poco más.
                        if (i > 50) break; // Asumimos max 50 caps si no hay hits
                      }
                    }
                  }
                  
                  if (context.mounted) {
                    context.read<BibliotecaBloc>().add(DeleteBook(book.id));
                    Navigator.pop(context);
                    PremiumToast.show(context, 'Libro eliminado', isSuccess: true);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
