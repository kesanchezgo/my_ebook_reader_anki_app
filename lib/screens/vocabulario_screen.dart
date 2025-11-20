import 'package:flutter/material.dart';
import '../models/anki_card.dart';
import '../services/anki_database_service.dart';
import '../services/export_service.dart';
import '../services/tts_service.dart';
import '../widgets/premium_toast.dart';
import 'dictionary_settings_screen.dart';

/// Pantalla para visualizar y gestionar el vocabulario guardado
class VocabularioScreen extends StatefulWidget {
  const VocabularioScreen({super.key});

  @override
  State<VocabularioScreen> createState() => _VocabularioScreenState();
}

class _VocabularioScreenState extends State<VocabularioScreen> {
  final AnkiDatabaseService _databaseService = AnkiDatabaseService();
  final ExportService _exportService = ExportService();
  final TtsService _ttsService = TtsService();
  
  List<AnkiCard> _cards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadCards();
  }
  
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
  
  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    try {
      final cards = await _databaseService.getAllCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando tarjetas: $e');
      setState(() => _isLoading = false);
    }
  }
  
  List<AnkiCard> get _filteredCards {
    if (_searchQuery.isEmpty) return _cards;
    
    final query = _searchQuery.toLowerCase();
    return _cards.where((card) {
      return card.word.toLowerCase().contains(query) ||
             card.definition.toLowerCase().contains(query) ||
             card.contexto.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _exportCards() async {
    if (_cards.isEmpty) {
      PremiumToast.show(context, 'No hay tarjetas para exportar', isWarning: true);
      return;
    }
    
    try {
      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Exportando tarjetas...'),
            ],
          ),
        ),
      );
      
      // Exportar y compartir
      await _exportService.exportAndShare(_cards);
      
      // Cerrar diálogo
      if (mounted) Navigator.pop(context);
      
      // Mostrar éxito
      if (mounted) {
        PremiumToast.show(context, '✓ ${_cards.length} tarjetas exportadas', isSuccess: true);
      }
      
    } catch (e) {
      // Cerrar diálogo
      if (mounted) Navigator.pop(context);
      
      // Mostrar error
      if (mounted) {
        PremiumToast.show(context, 'Error al exportar: $e', isError: true);
      }
    }
  }
  
  Future<void> _deleteCard(AnkiCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text('¿Eliminar "${card.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _databaseService.deleteCard(card.id);
      _loadCards();
      
      if (mounted) {
        PremiumToast.show(context, 'Tarjeta eliminada', isSuccess: true);
      }
    }
  }
  
  void _playAudio(String text, {bool isWord = true}) {
    if (isWord) {
      _ttsService.speakWord(text);
    } else {
      _ttsService.speakSentence(text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final stats = _exportService.getExportStats(_cards);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mi Vocabulario', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_rounded),
            tooltip: 'Diccionarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DictionarySettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Exportar a CSV',
            onPressed: _cards.isEmpty ? null : _exportCards,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar palabras...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: TextStyle(color: colorScheme.onSurface),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          
          // Estadísticas
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.style_rounded,
                      label: 'Tarjetas',
                      value: '${stats['total']}',
                    ),
                    Container(width: 1, height: 30, color: colorScheme.outlineVariant),
                    _StatItem(
                      icon: Icons.library_books_rounded,
                      label: 'Libros',
                      value: '${stats['books']}',
                    ),
                    Container(width: 1, height: 30, color: colorScheme.outlineVariant),
                    _StatItem(
                      icon: Icons.volume_up_rounded,
                      label: 'Con audio',
                      value: '${stats['withAudio']}',
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Lista de tarjetas
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _filteredCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.speaker_notes_off_rounded,
                              size: 80,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay tarjetas guardadas'
                                  : 'No se encontraron resultados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Selecciona texto en tus libros para crear tarjetas y repasar vocabulario.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = _filteredCards[index];
                          return _CardTile(
                            card: card,
                            onDelete: () => _deleteCard(card),
                            onPlayWord: () => _playAudio(card.word, isWord: true),
                            onPlaySentence: () => _playAudio(card.contexto, isWord: false),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final AnkiCard card;
  final VoidCallback onDelete;
  final VoidCallback onPlayWord;
  final VoidCallback onPlaySentence;
  
  const _CardTile({
    required this.card,
    required this.onDelete,
    required this.onPlayWord,
    required this.onPlaySentence,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                card.word.isNotEmpty ? card.word[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          title: Text(
            card.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              card.definition,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.volume_up_rounded, size: 22, color: colorScheme.primary),
                tooltip: 'Reproducir palabra',
                onPressed: onPlayWord,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Definición completa
                _buildSectionTitle(context, 'Definición'),
                const SizedBox(height: 6),
                Text(
                  card.definition,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Contexto/Oración
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(context, 'Contexto'),
                    IconButton(
                      onPressed: onPlaySentence,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      tooltip: 'Escuchar contexto',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer.withOpacity(0.3),
                        foregroundColor: colorScheme.secondary,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Text(
                    card.contexto,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Footer (Fuente y Acciones)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book_rounded, size: 14, color: colorScheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  card.fuente,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(card.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: 'Eliminar tarjeta',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
