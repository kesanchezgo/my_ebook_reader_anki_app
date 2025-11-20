import 'package:flutter/material.dart';
import '../models/anki_card.dart';
import '../services/anki_database_service.dart';
import '../services/dictionary_service.dart';
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
  final DictionaryService _dictionaryService = DictionaryService(); // Added service
  
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

  Future<void> _explainContext(String contextText) async {
    // Mostrar loading
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Analizando contexto con IA...',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final explanation = await _dictionaryService.explainContext(contextText);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (explanation != null) {
        _showExplanationModal(explanation, contextText);
      } else {
        PremiumToast.show(context, 'No se pudo obtener la explicación. Verifica tu conexión.', isWarning: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        PremiumToast.show(context, 'Error de conexión', isError: true);
      }
    }
  }

  void _showExplanationModal(Map<String, dynamic> data, String originalContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // Evita que se cierre al deslizar hacia abajo accidentalmente
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.0, // Permite cerrar al deslizar hasta el fondo
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.4], // Punto de anclaje "minimizado"
        builder: (_, controller) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight < 100) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Análisis de Contexto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.only(bottom: 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Contexto Original
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTEXTO ORIGINAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            originalContext,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Serif', // Si está disponible, o usa el default
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Idea Principal
                    _buildInfoCard(
                      context,
                      title: 'Idea Principal',
                      icon: Icons.lightbulb_outline_rounded,
                      content: Text(
                        data['main_idea'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Términos Complejos
                    if (data['complex_terms'] != null && (data['complex_terms'] as List).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'VOCABULARIO CLAVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...(data['complex_terms'] as List).map((term) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              term['term'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              term['explanation'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],

                    // Ejemplos
                    if (data['usage_examples'] != null && (data['usage_examples'] as List).isNotEmpty) ...[
                      _buildInfoCard(
                        context,
                        title: 'Ejemplos de Uso',
                        icon: Icons.format_quote_rounded,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (data['usage_examples'] as List).map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(Icons.circle, size: 6, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ex.toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],

                    // Nota Cultural (si existe)
                    if (data['cultural_note'] != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOTA CULTURAL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data['cultural_note'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
            }
          );
        }
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
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
                            onExplainContext: () => _explainContext(card.contexto),
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
  final VoidCallback onExplainContext;
  
  const _CardTile({
    required this.card,
    required this.onDelete,
    required this.onPlayWord,
    required this.onPlaySentence,
    required this.onExplainContext,
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
                
                if (card.example.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Ejemplo'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.tertiary.withOpacity(0.2)),
                    ),
                    child: Text(
                      card.example,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Contexto/Oración
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildSectionTitle(context, 'Contexto'),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onExplainContext,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          tooltip: 'Explicar con IA',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
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
