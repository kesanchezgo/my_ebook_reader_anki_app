import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../services/epub_service.dart';

/// Widget que muestra una tarjeta de libro en la biblioteca
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  Future<Uint8List?>? _coverFuture;
  int _totalSeconds = 0;

  @override
  void initState() {
    super.initState();
    _coverFuture = EpubService().getCoverImage(File(widget.book.filePath));
    _loadReadingTime();
  }

  @override
  void didUpdateWidget(BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar tiempo si el libro cambia o si se reconstruye el widget (ej. al volver del lector)
    if (widget.book.id != oldWidget.book.id || widget.book != oldWidget.book) {
       _coverFuture = EpubService().getCoverImage(File(widget.book.filePath));
       _loadReadingTime();
    } else {
      // Incluso si es el mismo libro, forzamos recarga del tiempo por si cambió en segundo plano
      _loadReadingTime();
    }
  }

  Future<void> _loadReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _totalSeconds = prefs.getInt('reading_time_${widget.book.id}') ?? 0;
      });
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = (seconds / 60).floor();
    if (minutes < 60) return '${minutes}m';
    final hours = (minutes / 60).floor();
    return '${hours}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portada (Icono)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(theme),
                  _buildDeleteButton(theme),
                  if (widget.book.progress > 0)
                    _buildProgressBadge(theme),
                ],
              ),
            ),
            
            // Info del libro
            Expanded(
              flex: 2,
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.author.isNotEmpty ? widget.book.author : 'Autor Desconocido',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_totalSeconds > 0) ...[
                          Icon(Icons.access_time_rounded, size: 12, color: theme.colorScheme.primary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_totalSeconds),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        // El porcentaje ya se muestra en el badge de la portada
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: FutureBuilder<Uint8List?>(
        future: _coverFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Fondo borroso (Blur Effect) para llenar espacios
                Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // Oscurecer un poco el fondo borroso
                  ),
                ),
                // 2. Imagen nítida en el centro
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          }
          // Fallback Gradient
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: Text(
                widget.book.title.isNotEmpty ? widget.book.title[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme) {
    return Positioned(
      top: 8,
      right: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onDelete,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Glassmorphism dark
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: const Icon(
                  Icons.delete_rounded, 
                  color: Colors.white70, 
                  size: 20
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBadge(ThemeData theme) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${widget.book.progress.toInt()}%',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
