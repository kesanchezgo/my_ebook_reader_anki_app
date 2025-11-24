import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../models/study_card.dart';
import '../services/study_database_service.dart';
import '../services/export_service.dart';
import '../services/tts_service.dart';
import '../widgets/premium_toast.dart';

/// Pantalla para visualizar y gestionar las fichas de idiomas (Adquisición)
class IdiomasScreen extends StatefulWidget {
  const IdiomasScreen({super.key});

  @override
  State<IdiomasScreen> createState() => _IdiomasScreenState();
}

class _IdiomasScreenState extends State<IdiomasScreen> {
  final StudyDatabaseService _databaseService = StudyDatabaseService();
  final ExportService _exportService = ExportService();
  final TtsService _ttsService = TtsService();
  
  List<StudyCard> _cards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _dbSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadCards();
    _dbSubscription = StudyDatabaseService.onDatabaseChanged.listen((_) => _loadCards());
  }
  
  @override
  void dispose() {
    _dbSubscription?.cancel();
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
  
  List<StudyCard> get _filteredCards {
    // 1. Filtrar por tipo (Solo Acquisition)
    final typeFiltered = _cards.where((card) {
      return card.type == StudyCardType.acquisition;
    }).toList();

    // 2. Filtrar por búsqueda
    if (_searchQuery.isEmpty) return typeFiltered;
    
    final query = _searchQuery.toLowerCase();
    return typeFiltered.where((card) {
      return card.word.toLowerCase().contains(query) ||
             card.definition.toLowerCase().contains(query) ||
             card.context.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _exportCards() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cards.isEmpty) {
      PremiumToast.show(context, l10n.noCardsToExport, isWarning: true);
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(l10n.exportingCards),
            ],
          ),
        ),
      );
      
      await _exportService.exportAndShare(_cards);
      
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        PremiumToast.show(context, l10n.cardsExported(_cards.length), isSuccess: true);
      }
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        PremiumToast.show(context, l10n.exportError(e.toString()), isError: true);
      }
    }
  }
  
  Future<void> _deleteCard(StudyCard card) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCard),
        content: Text(l10n.deleteCardConfirmation(card.word)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _databaseService.deleteCard(card.id);
      _loadCards();
      
      if (mounted) {
        PremiumToast.show(context, l10n.cardDeleted, isSuccess: true);
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Idiomas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: l10n.exportToCSV,
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchWords,
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
                              Icons.language_rounded,
                              size: 80,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay fichas de idiomas'
                                  : l10n.noResultsFound,
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
                                  'Activa el modo "Aprender" en ajustes y selecciona palabras para crear fichas de adquisición.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                            onPlaySentence: () => _playAudio(card.context, isWord: false),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final StudyCard card;
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
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  bool _showExampleTranslation = false;
  bool _showContextTranslation = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Extraer datos adicionales del content
    final irregularForms = widget.card.content['irregular_forms'] as List?;
    final wordDefinitions = widget.card.content['word_definitions'] as List?;
    final exampleTranslation = widget.card.content['example_translation'] as String?;
    final contextTranslation = widget.card.content['context_translation'] as String?;

    // Filtrar otras acepciones (excluir la principal)
    final otherDefinitions = wordDefinitions?.where((d) => d != widget.card.definition).toList() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
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
                widget.card.word.isNotEmpty ? widget.card.word[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          title: Text(
            widget.card.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.card.definition,
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
                tooltip: l10n.playWord,
                onPressed: widget.onPlayWord,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
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
                // Traducción Principal
                _buildSectionTitle(context, 'Traducción'),
                const SizedBox(height: 6),
                Text(
                  widget.card.definition,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                
                // Definiciones adicionales (Word Definitions)
                if (otherDefinitions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Otras Acepciones'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: otherDefinitions.map<Widget>((def) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          def.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Formas Irregulares
                if (irregularForms != null && irregularForms.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Formas Irregulares'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: irregularForms.map<Widget>((form) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          form.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (widget.card.example.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, l10n.example),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.card.example,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (exampleTranslation != null && exampleTranslation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildTranslationToggle(
                      context, 
                      isVisible: _showExampleTranslation,
                      onToggle: () => setState(() => _showExampleTranslation = !_showExampleTranslation),
                      text: exampleTranslation,
                    ),
                  ],
                ],
                
                if (widget.card.context.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  
                  // Contexto/Oración
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, l10n.originalContext),
                      IconButton(
                        onPressed: widget.onPlaySentence,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        tooltip: l10n.listenContext,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
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
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.card.context,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (contextTranslation != null && contextTranslation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildTranslationToggle(
                      context, 
                      isVisible: _showContextTranslation,
                      onToggle: () => setState(() => _showContextTranslation = !_showContextTranslation),
                      text: contextTranslation,
                    ),
                  ],
                ],
                
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
                              Icon(Icons.book_rounded, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.card.fuente,
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
                              Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(context, widget.card.createdAt),
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
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: l10n.deleteCard,
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
  
  Widget _buildTranslationToggle(BuildContext context, {
    required bool isVisible,
    required VoidCallback onToggle,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded, 
                  size: 14, 
                  color: colorScheme.primary
                ),
                const SizedBox(width: 6),
                Text(
                  'Traducción',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (isVisible)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
      ],
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
  
  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
