import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../services/local_storage_service.dart';
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../bloc/biblioteca_state.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/premium_toast.dart';
import '../widgets/purpose_modal.dart';
import 'lector_screen.dart';
import 'settings_screen.dart';

/// Pantalla principal que muestra la biblioteca de libros
class BibliotecaScreen extends StatelessWidget {
  const BibliotecaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.libraryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BibliotecaBloc, BibliotecaState>(
        listener: (context, state) {
          if (state is BibliotecaError) {
            PremiumToast.show(context, state.message, isError: true);
          } else if (state is BibliotecaBookImported) {
            PremiumToast.show(context, l10n.bookImported(state.book.title), isSuccess: true);
          }
        },
        builder: (context, state) {
          if (state is BibliotecaLoading || state is BibliotecaImporting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
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
          context.read<BibliotecaBloc>().add(ImportBook());
        },
        elevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: l10n.importEpubTooltip,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Widget para mostrar cuando no hay libros
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.library_books_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.libraryEmptyTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.libraryEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar la cuadrícula de libros
  Widget _buildBookGrid(BuildContext context, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Adjusted for new card height
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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
  void _openBook(BuildContext context, Book book) async {
    // Verificar si el libro ya tiene configuración de propósito
    if (book.studyMode == null) {
      // Mostrar modal de propósito
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PurposeModal(
          book: book,
          onConfigured: (configuredBook) {
            Navigator.pop(context); // Cerrar modal
            // Guardar configuración y abrir libro
            context.read<BibliotecaBloc>().add(UpdateBook(configuredBook));
            _navigateToReader(context, configuredBook);
          },
        ),
      );
    } else {
      _navigateToReader(context, book);
    }
  }

  void _navigateToReader(BuildContext context, Book book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectorScreen(book: book),
      ),
    );
    
    if (context.mounted) {
      if (result is Book) {
        // Si recibimos el libro actualizado, actualizamos directamente
        context.read<BibliotecaBloc>().add(UpdateBook(result));
      } else {
        // Fallback por si acaso
        context.read<BibliotecaBloc>().add(LoadBooks());
      }
    }
  }

  /// Elimina un libro de la biblioteca
  void _deleteBook(BuildContext context, Book book) {
    bool deleteData = false;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(l10n.deleteBookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteBookContent(book.title),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => setState(() => deleteData = !deleteData),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: deleteData,
                            activeColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (value) {
                              setState(() => deleteData = value ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.deleteReadingData,
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (deleteData) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('reading_time_${book.id}');
                    
                    // Eliminar posiciones de scroll por capítulo
                    for (int i = 0; i < 1000; i++) {
                      if (prefs.containsKey('scroll_${book.id}_$i')) {
                        await prefs.remove('scroll_${book.id}_$i');
                      } else {
                        if (i > 50) break; 
                      }
                    }

                    // Eliminar progreso de lectura (capítulo actual)
                    final storageService = await LocalStorageService.init();
                    await storageService.deleteProgress(book.id);
                  }
                  
                  if (context.mounted) {
                    context.read<BibliotecaBloc>().add(DeleteBook(book.id));
                    Navigator.pop(context);
                    PremiumToast.show(context, l10n.bookDeleted, isSuccess: true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.delete),
              ),
            ],
          );
        },
      ),
    );
  }
}
