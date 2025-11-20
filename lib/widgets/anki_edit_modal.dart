import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/anki_card.dart';
import '../services/anki_database_service.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import 'premium_toast.dart';

class AnkiEditModal extends StatefulWidget {
  final String word;
  final String context;
  final String bookTitle;
  final String bookId;

  const AnkiEditModal({
    super.key,
    required this.word,
    required this.context,
    required this.bookTitle,
    required this.bookId,
  });

  @override
  State<AnkiEditModal> createState() => _AnkiEditModalState();
}

class _AnkiEditModalState extends State<AnkiEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordController;
  late TextEditingController _definitionController;
  late TextEditingController _contextController;
  
  final AnkiDatabaseService _ankiDatabase = AnkiDatabaseService();
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _cardExists = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word);
    _contextController = TextEditingController(text: widget.context);
    _definitionController = TextEditingController();
    
    // Listeners para validación
    _wordController.addListener(_validateForm);
    _contextController.addListener(_validateForm);
    _definitionController.addListener(_validateForm);
    
    _searchDictionary();
    _checkDuplicate();
    _validateForm(); // Validación inicial
  }

  void _validateForm() {
    final isValid = _wordController.text.trim().isNotEmpty && 
                    _contextController.text.trim().isNotEmpty &&
                    _definitionController.text.trim().isNotEmpty;
    
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _searchDictionary() async {
    setState(() => _isSearching = true);
    
    try {
      final definition = await _dictionaryService.getDefinition(widget.word);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          if (definition.isNotEmpty) {
            _definitionController.text = definition;
            PremiumToast.show(context, 'Definición encontrada', isSuccess: true);
          } else {
            PremiumToast.show(context, 'No se encontró. Ingrésala manual');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _checkDuplicate() async {
    // Consulta AnkiDatabaseService.cardExists(word).
    // Usamos wordExistsInBook ya que es el método existente en el servicio.
    final exists = await _ankiDatabase.wordExistsInBook(widget.word, widget.bookId);
    if (mounted) {
      setState(() {
        _cardExists = exists;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cardId = const Uuid().v4();
      final audioPath = await _ttsService.generateWordAudio(_wordController.text, cardId);

      final newCard = AnkiCard(
        id: cardId,
        bookId: widget.bookId,
        word: _wordController.text,
        definition: _definitionController.text,
        contexto: _contextController.text,
        audioPath: audioPath,
        fuente: widget.bookTitle,
        createdAt: DateTime.now(),
      );
      
      await _ankiDatabase.insertCard(newCard);
      
      if (mounted) {
        Navigator.pop(context);
        PremiumToast.show(context, 'Guardado en Anki', isSuccess: true);
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        PremiumToast.show(context, 'Error: $e', isError: true);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;

    // UI limpia y oscura
    return Container(
      color: surfaceColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Guardar en Anki',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_cardExists)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta palabra ya existe en tu colección.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            TextFormField(
              controller: _wordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Palabra',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                errorStyle: const TextStyle(color: Colors.redAccent),
                filled: true,
                fillColor: Colors.black12,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Stack(
              children: [
                TextFormField(
                  controller: _definitionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Definición',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
                if (_isSearching)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.5)),
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contextController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Contexto',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                errorStyle: TextStyle(color: Colors.redAccent),
                filled: true,
                fillColor: Colors.black12,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: (_isLoading || _cardExists || !_isFormValid) ? null : _saveCard,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      'GUARDAR', 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: (_cardExists || !_isFormValid) ? Colors.grey[500] : Colors.white
                      )
                    ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
