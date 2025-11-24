import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../models/study_card.dart';
import '../services/study_database_service.dart';
import '../services/dictionary_service.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import 'premium_toast.dart';

class StudyEditModal extends StatefulWidget {
  final String word;
  final String context;
  final String bookTitle;
  final String bookId;
  final String? initialDefinition;
  final String? initialExample;
  final Map<String, dynamic>? learningData;

  const StudyEditModal({
    super.key,
    required this.word,
    required this.context,
    required this.bookTitle,
    required this.bookId,
    this.initialDefinition,
    this.initialExample,
    this.learningData,
  });

  @override
  State<StudyEditModal> createState() => _StudyEditModalState();
}

class _StudyEditModalState extends State<StudyEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordController;
  late TextEditingController _definitionController;
  late TextEditingController _contextController;
  late TextEditingController _exampleController;
  
  final StudyDatabaseService _studyDatabase = StudyDatabaseService();
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _cardExists = false;
  bool _isFormValid = false;
  String? _definitionSource;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word);
    _contextController = TextEditingController(text: widget.context);
    
    // Lógica de inicialización según modo (Learning vs Native)
    if (widget.learningData != null) {
      // Modo Learning: Usar datos de IA
      final data = widget.learningData!;
      _definitionController = TextEditingController(text: data['context_translation'] ?? '');
      
      String example = data['example_original'] ?? '';
      if (data['example_translation'] != null) {
        example += '\n(${data['example_translation']})';
      }
      _exampleController = TextEditingController(text: example);
      _definitionSource = 'Gemini AI (Learning)';
    } else {
      // Modo Native: Usar datos pasados o buscar
      _definitionController = TextEditingController(text: widget.initialDefinition ?? '');
      _exampleController = TextEditingController(text: widget.initialExample ?? '');
    }
    
    // Listeners para validación
    _wordController.addListener(_validateForm);
    _contextController.addListener(_validateForm);
    _definitionController.addListener(_validateForm);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.learningData == null && (widget.initialDefinition == null || widget.initialDefinition!.isEmpty)) {
        _searchDictionary();
      }
    });

    _checkDuplicate();
    _validateForm(); // Validación inicial
  }

  void _requestManualContext() {
    Navigator.pop(context, {
      'action': 'manual_context',
      'formData': {
        'word': _wordController.text,
        'definition': _definitionController.text,
        'example': _exampleController.text,
        'context': _contextController.text,
      }
    });
  }

  void _validateForm() {
    final isValid = _wordController.text.trim().isNotEmpty && 
                    _definitionController.text.trim().isNotEmpty;
    
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _searchDictionary() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Verificación rápida de API Key para diagnóstico
    final priorities = SettingsService.instance.dictionaryPriority;
    if (priorities.isNotEmpty && priorities.first == 'gemini') {
       if (SettingsService.instance.geminiApiKey.isEmpty) {
         PremiumToast.show(context, "Falta la API Key de Gemini. Revisa la configuración.", isWarning: true);
       }
    }

    setState(() {
      _isSearching = true;
      _definitionSource = null;
    });
    
    try {
      final result = await _dictionaryService.getDefinition(widget.word);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          // Si la definición es válida y no es el mensaje de error por defecto
          if (result.definition.isNotEmpty && !result.definition.contains('no encontrada')) {
            _definitionController.text = result.definition;
            if (result.example != null && result.example!.isNotEmpty) {
              _exampleController.text = result.example!;
            }
            _definitionSource = result.source;
            // No mostramos toast si se encuentra, para una experiencia más limpia
          } else {
            // No rellenamos el campo con texto de error, lo dejamos vacío para que el usuario escriba
            PremiumToast.show(context, l10n.definitionNotFound, isWarning: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        PremiumToast.show(context, l10n.searchError, isError: true);
      }
    }
  }

  Future<void> _checkDuplicate() async {
    // Consulta StudyDatabaseService.wordExistsInBook(word).
    final exists = await _studyDatabase.wordExistsInBook(widget.word, widget.bookId);
    if (mounted) {
      setState(() {
        _cardExists = exists;
      });
    }
  }

  Future<void> _saveCard() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cardId = const Uuid().v4();
      final audioPath = await _ttsService.generateWordAudio(_wordController.text, cardId);

      final newCard = StudyCard(
        id: cardId,
        bookId: widget.bookId,
        type: StudyCardType.enrichment, // Por defecto enrichment (definición)
        content: {
          'word': _wordController.text,
          'definition': _definitionController.text,
          'context': _contextController.text,
          'example': _exampleController.text,
        },
        audioPath: audioPath,
        fuente: widget.bookTitle,
        createdAt: DateTime.now(),
      );
      
      await _studyDatabase.insertCard(newCard);
      
      if (mounted) {
        Navigator.pop(context);
        PremiumToast.show(context, l10n.savedToStudy, isSuccess: true);
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        PremiumToast.show(context, l10n.errorGeneric(e.toString()), isError: true);
      }
    }
  }

  @override
  void dispose() {
    _wordController.removeListener(_validateForm);
    _contextController.removeListener(_validateForm);
    _definitionController.removeListener(_validateForm);
    _wordController.dispose();
    _definitionController.dispose();
    _contextController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
  
              // Header
              Row(
                children: [
                  Icon(Icons.bookmark_add_rounded, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    l10n.createStudyCard,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Warning Card
              if (_cardExists)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.wordAlreadyExists,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
  
              // Word Input
              _buildModernTextField(
                controller: _wordController,
                label: l10n.word,
                icon: Icons.translate_rounded,
                theme: theme,
              ),
              const SizedBox(height: 16),
              
              // Definition Source Chip
              if (_definitionSource != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.source(_definitionSource!),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
  
              // Definition Input
              _buildModernTextField(
                controller: _definitionController,
                label: l10n.definition,
                icon: Icons.menu_book_rounded,
                theme: theme,
                maxLines: 3,
                isLoading: _isSearching,
              ),
              
              // Learning Mode: Word Definitions Suggestions
              if (widget.learningData != null && widget.learningData!['word_definitions'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (widget.learningData!['word_definitions'] as List).map<Widget>((def) {
                      return ActionChip(
                        label: Text(def.toString(), style: textTheme.bodySmall),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          final currentText = _definitionController.text;
                          if (currentText.isEmpty) {
                            _definitionController.text = def.toString();
                          } else {
                            _definitionController.text = '$currentText\n${def.toString()}';
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),

              // Learning Mode: Irregular Forms
              if (widget.learningData != null && 
                  widget.learningData!['irregular_forms'] != null && 
                  (widget.learningData!['irregular_forms'] as List).isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.tertiary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.tertiary),
                          const SizedBox(width: 6),
                          Text(
                            'Formas Irregulares',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: (widget.learningData!['irregular_forms'] as List).map<Widget>((form) {
                          return Chip(
                            label: Text(form.toString(), style: textTheme.bodySmall),
                            backgroundColor: colorScheme.surface,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: colorScheme.tertiary.withOpacity(0.3)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
  
              // Example Input (Optional)
              _buildModernTextField(
                controller: _exampleController,
                label: l10n.exampleOptional,
                icon: Icons.lightbulb_outline_rounded,
                theme: theme,
                maxLines: 2,
                isRequired: false,
              ),
              const SizedBox(height: 16),
  
              // Context Input
              _buildModernTextField(
                controller: _contextController,
                label: '${l10n.context} (Opcional)',
                icon: Icons.format_quote_rounded,
                theme: theme,
                maxLines: 2,
                isRequired: false,
              ),
              
              // Manual Context Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _requestManualContext,
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: Text(l10n.selectFromBook),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: (_isLoading || _cardExists || !_isFormValid) ? null : _saveCard,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, 
                          color: colorScheme.onPrimary
                        )
                      )
                    : Text(
                        l10n.saveCard, 
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.onPrimary, // Forzar color para contraste
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    int maxLines = 1,
    bool isLoading = false,
    bool isRequired = true,
  }) {
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
          suffixIcon: isLoading 
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)
                ),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: (value) {
          if (!isRequired) return null;
          if (value == null || value.trim().isEmpty) return ''; // Validación visual manejada por el botón
          return null;
        },
      ),
    );
  }
}
