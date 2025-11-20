import 'package:flutter/material.dart';
import '../models/anki_card.dart';
import '../services/anki_database_service.dart';
import '../services/export_service.dart';
import '../services/tts_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tarjetas para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${_cards.length} tarjetas exportadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      // Cerrar diálogo
      if (mounted) Navigator.pop(context);
      
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Tarjeta eliminada'),
            duration: Duration(seconds: 2),
          ),
        );
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Vocabulario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
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
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar a CSV',
            onPressed: _cards.isEmpty ? null : _exportCards,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar palabras...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Estadísticas
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.book,
                        label: 'Tarjetas',
                        value: '${stats['total']}',
                      ),
                      _StatItem(
                        icon: Icons.library_books,
                        label: 'Libros',
                        value: '${stats['books']}',
                      ),
                      _StatItem(
                        icon: Icons.volume_up,
                        label: 'Con audio',
                        value: '${stats['withAudio']}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Lista de tarjetas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.speaker_notes_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay tarjetas guardadas'
                                  : 'No se encontraron resultados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Selecciona texto en tus libros para crear tarjetas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            card.word[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          card.word,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          card.definition,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              tooltip: 'Reproducir palabra',
              onPressed: onPlayWord,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Eliminar',
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Definición completa
                const Text(
                  'Definición:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(card.definition),
                
                const SizedBox(height: 12),
                
                // Contexto/Oración
                Row(
                  children: [
                    const Text(
                      'Contexto:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.play_circle, size: 20),
                      tooltip: 'Reproducir oración',
                      onPressed: onPlaySentence,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  card.contexto,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                
                const SizedBox(height: 12),
                
                // Fuente
                Row(
                  children: [
                    const Icon(Icons.book, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        card.fuente,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Fecha
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(card.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
