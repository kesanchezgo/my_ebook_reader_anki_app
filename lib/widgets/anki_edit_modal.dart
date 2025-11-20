import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/anki_card.dart';
import '../services/anki_database_service.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';

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
  late TextEditingController _wordController;
  late TextEditingController _definitionController;
  late TextEditingController _contextController;
  
  final AnkiDatabaseService _ankiDatabase = AnkiDatabaseService();
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  
  bool _isLoading = false;
  bool _cardExists = false;

  @override
  void initState() {
    super.initState();
    // Asigna word y context a sus TextEditingController inmediatamente.
    _wordController = TextEditingController(text: widget.word);
    _contextController = TextEditingController(text: widget.context);
    _definitionController = TextEditingController();
    
    // Llama a _searchDictionary().
    _searchDictionary();
    
    // Validación de duplicados
    _checkDuplicate();
  }

  Future<void> _searchDictionary() async {
    // Llama a DictionaryService.getDefinition(widget.word).
    final definition = await _dictionaryService.getDefinition(widget.word);
    
    if (mounted) {
      setState(() {
        // Si encuentra definición, actualiza el controller de definición
        _definitionController.text = definition;
      });
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
    if (_wordController.text.isEmpty) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado en Anki'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _definitionController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI limpia y oscura
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guardar en Anki',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          
          if (_cardExists)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta palabra ya existe en tu colección.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          TextField(
            controller: _wordController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Palabra',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _definitionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Definición',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _contextController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Contexto',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cardExists ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: (_isLoading || _cardExists) ? null : _saveCard,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('GUARDAR', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
