import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/study_card.dart';
import '../services/epub_service.dart';
import '../services/local_storage_service.dart';
import '../services/settings_service.dart';
// import '../services/context_service.dart';
import '../services/dictionary_service.dart';
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../widgets/study_edit_modal.dart';
import '../widgets/premium_toast.dart';
import '../widgets/ai_result_modal.dart';

enum ReaderMode {
  reading,
  capturingWord,
  capturingContext,
  analyzing,
  findingSynonyms
}

class LectorScreen extends StatefulWidget {
  final Book book;

  const LectorScreen({super.key, required this.book});

  @override
  State<LectorScreen> createState() => _LectorScreenState();
}

class _LectorScreenState extends State<LectorScreen> with WidgetsBindingObserver {
  late Future<List<ChapterData>> _chaptersFuture;
  PageController _pageController = PageController();
  
  // Estado de configuración de lectura
  late double _fontSize;
  late String _fontFamily;
  late Color _backgroundColor;
  late Color _textColor;
  late TextAlign _textAlign;
  
  int _currentChapterIndex = 0;
  String _currentSelection = "";
  
  // UI Controls
  bool _showControls = true;
  
  // Reading Stats
  Timer? _readingTimer;
  int _sessionSeconds = 0; // Tiempo de la sesión actual (empieza en 0)
  int _accumulatedSeconds = 0; // Tiempo total acumulado histórico
  
  // Progress
  double _globalProgress = 0.0;
  double _chapterProgress = 0.0;
  final Map<int, double> _chaptersProgressMap = {};
  bool _canPop = false;
  
  late Book _book; // Libro con estado local mutable (para configuración)
  
  // Estado temporal para selección manual de contexto
  Map<String, dynamic>? _pendingStudyData;
  String? _capturedWordForAI;
  
  // final ContextService _contextService = ContextService();
  final DictionaryService _dictionaryService = DictionaryService();
  
  ReaderMode _readerMode = ReaderMode.reading;
  bool _isAnalyzing = false;
  bool _isToolsMenuOpen = false;
  
  // FAB Opacity
  double _fabOpacity = 1.0;
  Timer? _fabOpacityTimer;
  int _selectionClearToken = 0;

  void _onUserInteraction() {
    if (_fabOpacity != 1.0) {
      setState(() => _fabOpacity = 1.0);
    }
    _fabOpacityTimer?.cancel();
    _fabOpacityTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_isToolsMenuOpen) {
        setState(() => _fabOpacity = 0.3);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    WidgetsBinding.instance.addObserver(this);
    _chaptersFuture = EpubService().loadChapters(File(widget.book.filePath));
    _loadSettings();
    
    // Inicializar progreso global desde el libro para evitar reinicios a 0
    _globalProgress = widget.book.progressPercentage / 100.0;
    
    _loadProgress();
    _startReadingTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveReadingTime();
      _saveCurrentProgress();
    }
  }

  Book _getCurrentBookState() {
    return _book.copyWith(
      currentPage: _currentChapterIndex,
      progressPercentage: _globalProgress * 100,
    );
  }

  void _handleExit() {
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final updatedBook = _getCurrentBookState();
        Navigator.pop(context, updatedBook);
      }
    });
  }

  void _saveCurrentProgress() {
    // Intentar guardar incluso si está desmontando, siempre que el contexto sea válido
    try {
      final updatedBook = _getCurrentBookState();
      context.read<BibliotecaBloc>().add(UpdateBook(updatedBook));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void _loadSettings() {
    final settings = SettingsService.instance;
    _fontSize = settings.fontSize;
    _fontFamily = settings.fontFamily;
    final theme = settings.currentTheme;
    _backgroundColor = theme.backgroundColor;
    _textColor = theme.textColor;
    _textAlign = settings.textAlign == 'justify' ? TextAlign.justify : TextAlign.left;
  }

  Future<void> _loadProgress() async {
    try {
      final storageService = await LocalStorageService.init();
      final savedPage = await storageService.getProgress(widget.book.id);
      
      // Cargar tiempo de lectura acumulado (simulado por ahora o desde prefs)
      final prefs = await SharedPreferences.getInstance();
      _accumulatedSeconds = prefs.getInt('reading_time_${widget.book.id}') ?? 0;
      // _sessionSeconds empieza en 0 por defecto

      if (mounted) {
        setState(() {
          _currentChapterIndex = savedPage;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(savedPage);
          } else {
            _pageController = PageController(initialPage: savedPage);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _saveProgress(int index) async {
    try {
      final storageService = await LocalStorageService.init();
      await storageService.saveProgress(widget.book.id, index);
      
      // Guardar también el progreso global en el objeto Book
      if (mounted) {
        final updatedBook = _book.copyWith(
          currentPage: index,
          progressPercentage: _globalProgress * 100,
        );
        // Actualizamos _book localmente también para mantener consistencia
        _book = updatedBook;
        context.read<BibliotecaBloc>().add(UpdateBook(updatedBook));
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }
  
  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionSeconds++;
      });
      // Guardar cada minuto para no saturar
      if (_sessionSeconds % 60 == 0) {
        _saveReadingTime();
      }
    });
  }
  
  Future<void> _saveReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos el total (acumulado histórico + sesión actual)
    await prefs.setInt('reading_time_${widget.book.id}', _accumulatedSeconds + _sessionSeconds);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatReadingTime() {
    // Mostramos solo el tiempo de la sesión actual
    final duration = Duration(seconds: _sessionSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final l10n = AppLocalizations.of(context)!;

        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            l10n.settings,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await SettingsService.instance.resetReaderSettings();
                          _loadSettings();
                          setState(() {});
                          setModalState(() {});
                        },
                        icon: Icon(Icons.refresh_rounded, size: 18, color: colorScheme.primary),
                        label: Text(
                          l10n.restore, 
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Tamaño de fuente
                  Text(
                    l10n.textSize,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Aa', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                            Text('${_fontSize.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            Text('Aa', style: TextStyle(fontSize: 24, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.onSurfaceVariant.withOpacity(0.2),
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withOpacity(0.1),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _fontSize,
                            min: 14.0,
                            max: 32.0,
                            divisions: 18,
                            onChanged: (value) {
                              setModalState(() => _fontSize = value);
                              setState(() => _fontSize = value);
                              SettingsService.instance.setFontSize(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tipo de fuente
                  Text(
                    l10n.typography,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _fontFamily,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                        dropdownColor: colorScheme.surfaceContainerHighest,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        items: ['Merriweather', 'Lato', 'Lora', 'Roboto Mono']
                            .map((font) => DropdownMenuItem(
                                  value: font,
                                  child: Text(
                                    font,
                                    style: GoogleFonts.getFont(font),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => _fontFamily = value);
                            setState(() => _fontFamily = value);
                            SettingsService.instance.setFontFamily(value);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Alineación
                  Text(
                    l10n.alignment,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAlignButton(
                            l10n.justified, 
                            TextAlign.justify, 
                            Icons.format_align_justify_rounded,
                            setModalState,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildAlignButton(
                            l10n.left, 
                            TextAlign.left, 
                            Icons.format_align_left_rounded,
                            setModalState,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Modo de Lectura
                  Text(
                    l10n.readingMode,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildModeOption(
                          context,
                          title: l10n.nativeMode,
                          subtitle: l10n.nativeModeDesc,
                          icon: Icons.school_rounded,
                          isSelected: _book.studyMode == 'native_vocab' || _book.studyMode == null,
                          onTap: () {
                            setState(() {
                              _book = _book.copyWith(studyMode: 'native_vocab');
                            });
                            setModalState(() {});
                            context.read<BibliotecaBloc>().add(UpdateBook(_book));
                          },
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.2)),
                        _buildModeOption(
                          context,
                          title: l10n.studyMode,
                          subtitle: l10n.studyModeDesc,
                          icon: Icons.translate_rounded,
                          isSelected: _book.studyMode == 'learn_language',
                          onTap: () {
                            setState(() {
                              _book = _book.copyWith(studyMode: 'learn_language');
                            });
                            setModalState(() {});
                            context.read<BibliotecaBloc>().add(UpdateBook(_book));
                          },
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.2)),
                        _buildModeOption(
                          context,
                          title: l10n.readOnlyMode,
                          subtitle: l10n.readOnlyModeDesc,
                          icon: Icons.menu_book_rounded,
                          isSelected: _book.studyMode == 'read_only',
                          onTap: () {
                            setState(() {
                              _book = _book.copyWith(studyMode: 'read_only');
                            });
                            setModalState(() {});
                            context.read<BibliotecaBloc>().add(UpdateBook(_book));
                          },
                        ),
                      ],
                    ),
                  ),
                  

                  
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAlignButton(
    String label, 
    TextAlign align, 
    IconData icon,
    StateSetter setModalState,
    ColorScheme colorScheme,
  ) {
    final isSelected = _textAlign == align;
    return GestureDetector(
      onTap: () {
        setModalState(() => _textAlign = align);
        setState(() => _textAlign = align);
        SettingsService.instance.setTextAlign(align == TextAlign.justify ? 'justify' : 'left');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _toggleToolsMenu() {
    if (_isAnalyzing) {
      setState(() {
        _isAnalyzing = false;
        _readerMode = ReaderMode.reading;
        _showControls = true;
        _selectionClearToken++;
        _pendingStudyData = null;
      });
      return;
    }

    if (_readerMode != ReaderMode.reading) {
      if (_readerMode == ReaderMode.capturingContext && _pendingStudyData != null) {
        _restorePendingCard();
        return;
      }

      _setReaderMode(ReaderMode.reading);
      setState(() {
        _selectionClearToken++;
        _pendingStudyData = null;
        _capturedWordForAI = null;
      });
      return;
    }

    setState(() {
      _isToolsMenuOpen = !_isToolsMenuOpen;
      if (_isToolsMenuOpen) {
        _fabOpacity = 1.0;
        _fabOpacityTimer?.cancel();
      } else {
        _onUserInteraction();
      }
    });
  }

  void _setReaderMode(ReaderMode mode) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _readerMode = mode;
      _isToolsMenuOpen = false;
      if (mode != ReaderMode.reading) {
        _showControls = false;
      } else {
        _showControls = true;
      }
    });
    
    String message = '';
    switch (mode) {
      case ReaderMode.capturingWord:
        message = l10n.promptSelectWord;
        break;
      case ReaderMode.capturingContext:
        final word = _capturedWordForAI ?? _pendingStudyData?['word'] ?? '...';
        message = l10n.promptSelectContext(word);
        break;
      case ReaderMode.analyzing:
        message = l10n.promptSelectText;
        break;
      case ReaderMode.findingSynonyms:
        message = l10n.promptSelectWord;
        break;
      case ReaderMode.reading:
        break;
    }
    
    if (message.isNotEmpty) {
      PremiumToast.show(context, message);
    }
  }

  void _restorePendingCard() async {
    _setReaderMode(ReaderMode.reading);
    setState(() => _selectionClearToken++);

    if (_pendingStudyData == null) return;

    final data = _pendingStudyData!;
    setState(() => _pendingStudyData = null);

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StudyEditModal(
        word: data['word'] ?? '',
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        context: data['context'] ?? '',
        initialDefinition: data['definition'] ?? '',
        initialExample: data['example'] ?? '',
      ),
    );

    if (result != null && result is Map && result['action'] == 'manual_context') {
      setState(() {
        _pendingStudyData = result['formData'];
      });
      _setReaderMode(ReaderMode.capturingContext);
    }
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _readingTimer?.cancel();
    _saveReadingTime();
    _saveCurrentProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Contenido Principal
          GestureDetector(
            onTap: _toggleControls,
            child: FutureBuilder<List<ChapterData>>(
              future: _chaptersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorLoadingBook(snapshot.error.toString()), style: TextStyle(color: _textColor)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(l10n.errorLoadingContent, style: TextStyle(color: _textColor)));
                }

                final chapters = snapshot.data!;

                return PageView.builder(
                  controller: _pageController,
                  itemCount: chapters.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentChapterIndex = index;
                      // Recuperar el progreso del nuevo capítulo si ya existe en el mapa
                      _chapterProgress = _chaptersProgressMap[index] ?? 0.0;
                      
                      // Recalcular progreso global basado en el nuevo capítulo
                      final totalChapters = chapters.length;
                      if (totalChapters > 0) {
                        _globalProgress = (index + _chapterProgress) / totalChapters;
                      }
                    });
                    _saveProgress(index);
                  },
                  itemBuilder: (context, index) {
                    return _ChapterView(
                      key: ValueKey('chapter_$index'),
                      chapter: chapters[index],
                      bookId: widget.book.id,
                      chapterIndex: index,
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                      textColor: _textColor,
                      textAlign: _textAlign,
                      readerMode: _readerMode,
                      onUserInteraction: _onUserInteraction,
                      selectionClearToken: _selectionClearToken,
                      studyMode: _book.studyMode,
                      onSelectionChanged: (selection) {
                        setState(() => _currentSelection = selection);
                      },
                      onProgressChanged: (chapterProgress) {
                        // Guardar en el mapa siempre para tenerlo listo al cambiar de página
                        _chaptersProgressMap[index] = chapterProgress;

                        // Solo actualizar la UI si es el capítulo actual
                        if (index == _currentChapterIndex) {
                          if ((chapterProgress - _chapterProgress).abs() > 0.001) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _chapterProgress = chapterProgress);
                            });
                          }

                          // Calcular progreso global: (capítulo actual + progreso del capítulo) / total capítulos
                          final totalChapters = chapters.length;
                          if (totalChapters > 0) {
                            final globalProgress = (index + chapterProgress) / totalChapters;
                            
                            // Actualizar solo si hay cambio significativo
                            if ((globalProgress - _globalProgress).abs() > 0.001) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => _globalProgress = globalProgress);
                                }
                              });
                            }
                          }
                        }
                      },
                      onSaveToStudy: (double scrollPercentage) async {
                        if (_currentSelection.isEmpty) {
                          PremiumToast.show(context, l10n.selectWordFirst, isError: true);
                          return;
                        }

                        if (_readerMode == ReaderMode.analyzing) {
                           setState(() => _isAnalyzing = true);
                           final result = await _dictionaryService.explainContext(_currentSelection);
                           
                           // Check if cancelled
                           if (!mounted || _readerMode == ReaderMode.reading) {
                             if (mounted) setState(() => _isAnalyzing = false);
                             return;
                           }

                           if (mounted) setState(() => _isAnalyzing = false);
                           

                           // Reset mode to clear banner
                           _setReaderMode(ReaderMode.reading);

                           if (result != null && mounted) {
                             await showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (context) => AiResultModal(
                                 type: AiResultType.analysis,
                                 data: result,
                                 source: result['source'] ?? 'IA',
                                 originalText: _currentSelection,
                               ),
                             );
                             if (mounted) setState(() => _showControls = true);
                           } else if (mounted) {
                             PremiumToast.show(context, l10n.explanationError, isError: true);
                             if (mounted) setState(() => _showControls = true);
                           }
                           return;
                        }
                        
                        if (_readerMode == ReaderMode.findingSynonyms) {
                           setState(() => _isAnalyzing = true);
                           final result = await _dictionaryService.getSynonyms(_currentSelection);
                           

                           // Check if cancelled
                           if (!mounted || _readerMode == ReaderMode.reading) {
                             if (mounted) setState(() => _isAnalyzing = false);
                             return;
                           }

                           if (mounted) setState(() => _isAnalyzing = false);
                           

                           // Reset mode to clear banner
                           _setReaderMode(ReaderMode.reading);

                           if (result != null && mounted) {
                             await showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (context) => AiResultModal(
                                 type: AiResultType.synonyms,
                                 data: result,
                                 source: result['source'] ?? 'IA',
                                 originalText: _currentSelection,
                               ),
                             );
                             if (mounted) setState(() => _showControls = true);
                           } else if (mounted) {
                             PremiumToast.show(context, l10n.explanationError, isError: true);
                             if (mounted) setState(() => _showControls = true);
                           }
                           return;
                        }

                        // --- MODO APRENDIZAJE (AI) ---
                        // Priorizar configuración del libro, luego global
                        final bookMode = _book.studyMode;
                        final globalMode = SettingsService.instance.studyMode;
                        final isLearningMode = bookMode == 'learn_language' || (bookMode == null && globalMode == 'learning');
                        
                        if (isLearningMode && _pendingStudyData == null) {
                           // Paso 1: Capturar Palabra
                           if (_capturedWordForAI == null) {
                               setState(() {
                                 _capturedWordForAI = _currentSelection;
                               });
                               _setReaderMode(ReaderMode.capturingContext);
                               PremiumToast.show(context, "Palabra capturada. Ahora selecciona la oración de contexto.");
                               return;
                           }
                           
                           // Paso 2: Capturar Contexto y Analizar
                           setState(() => _isAnalyzing = true);
                           
                           final word = _capturedWordForAI!;
                           final contextSentence = _currentSelection;
                           
                           Map<String, dynamic>? result;
                           try {
                             result = await _dictionaryService.analyzeWordForLearning(
                               word: word,
                               contextSentence: contextSentence, 
                               sourceLang: _book.language ?? 'Inglés', 
                               targetLang: _book.targetLanguage ?? 'Español',
                               bookInfo: widget.book.title,
                             );
                           } catch (e) {
                             if (mounted) {
                               String message = e.toString();
                               if (message.contains("Exception: ")) {
                                 message = message.replaceAll("Exception: ", "");
                               }
                               PremiumToast.show(context, message, isError: true);
                             }
                           }

                           if (!mounted) return;
                           setState(() {
                               _isAnalyzing = false;
                               _capturedWordForAI = null;
                           });

                           if (result != null) {
                              // Resetear modo a lectura para limpiar banner
                              _setReaderMode(ReaderMode.reading);
                              
                              final modalResult = await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => StudyEditModal(
                                  word: word,
                                  bookId: widget.book.id,
                                  bookTitle: widget.book.title,
                                  context: contextSentence, // Contexto seleccionado
                                  learningData: result, // Pasamos los datos de IA
                                  mode: StudyCardType.acquisition,
                                ),
                              );
                              
                              if (modalResult != null && modalResult is Map && modalResult['action'] == 'manual_context') {
                                setState(() {
                                  _pendingStudyData = modalResult['formData'];
                                });
                                _setReaderMode(ReaderMode.capturingContext);
                              }
                              return;
                           }
                           // Si falla la IA, continuamos con el flujo normal (fallback)
                        }
                        // -----------------------------

                        String initialContext = '';
                        String initialWord = '';
                        String initialDefinition = '';
                        String initialExample = '';

                        if (_pendingStudyData != null) {
                          initialContext = _currentSelection;
                          initialWord = _pendingStudyData!['word'] ?? '';
                          initialDefinition = _pendingStudyData!['definition'] ?? '';
                          initialExample = _pendingStudyData!['example'] ?? '';
                          setState(() => _pendingStudyData = null);
                        } else if (_readerMode == ReaderMode.capturingContext) {
                           initialContext = _currentSelection;
                        } else if (_readerMode == ReaderMode.capturingWord) {
                           initialWord = _currentSelection;
                           initialContext = ''; 
                        } else {
                          initialWord = _currentSelection;
                          initialContext = '';
                        }

                        // Ocultar banner antes de abrir el modal
                        if (_readerMode != ReaderMode.reading) {
                          _setReaderMode(ReaderMode.reading);
                        }

                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => StudyEditModal(
                            word: initialWord,
                            bookId: widget.book.id,
                            bookTitle: widget.book.title,
                            context: initialContext,
                            initialDefinition: initialDefinition,
                            initialExample: initialExample,
                            mode: isLearningMode ? StudyCardType.acquisition : StudyCardType.enrichment,
                          ),
                        );

                        if (result != null && result is Map && result['action'] == 'manual_context') {
                          setState(() {
                            _pendingStudyData = result['formData'];
                          });
                          _setReaderMode(ReaderMode.capturingContext);
                        }
                      },
                      isSelectingContext: _pendingStudyData != null,
                    );
                  },
                );
              },
            ),
          ),

          // Barra Superior (AppBar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -80,
            left: 0,
            right: 0,
            child: AppBar(
              title: Text(
                '${widget.book.title} (${_currentChapterIndex + 1})',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E).withOpacity(0.95),
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _showSettingsModal,
                ),
              ],
            ),
          ),

          // Banner de Instrucciones (Top)
          if (_readerMode != ReaderMode.reading || _isAnalyzing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 12,
                  left: 16,
                  right: 8
                ),
                child: Row(
                  children: [
                    if (_isAnalyzing)
                      SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Theme.of(context).colorScheme.onPrimaryContainer
                        )
                      )
                    else
                      Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isAnalyzing ? _getAnalyzingMessage(l10n) : _getInstructionText(l10n),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isAnalyzing)
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

          // Barra Inferior (Progreso)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -60,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              color: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E).withOpacity(0.95),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _formatReadingTime(),
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LinearProgressIndicator(
                          value: _chapterProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          minHeight: 2,
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<List<ChapterData>>(
                          future: _chaptersFuture,
                          builder: (context, snapshot) {
                            final totalChapters = snapshot.data?.length ?? 0;
                            return Text(
                              l10n.chapterProgress(_currentChapterIndex + 1, totalChapters, (_chapterProgress * 100).toInt()),
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 10),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Speed Dial Menu (Moderno)
          if (_isToolsMenuOpen)
            Positioned(
              bottom: 160,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildModernSpeedDialItem(
                    icon: Icons.compare_arrows,
                    label: l10n.readerToolSynonyms,
                    onTap: () {
                      _toggleToolsMenu();
                      _setReaderMode(ReaderMode.findingSynonyms);
                    },
                    delay: 0,
                  ),
                  const SizedBox(height: 16),
                  _buildModernSpeedDialItem(
                    icon: Icons.analytics,
                    label: l10n.readerToolAnalyze,
                    onTap: () {
                      _toggleToolsMenu();
                      _setReaderMode(ReaderMode.analyzing);
                    },
                    delay: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildModernSpeedDialItem(
                    icon: Icons.text_fields,
                    label: l10n.readerToolCapture,
                    onTap: () {
                      _toggleToolsMenu();
                      _setReaderMode(ReaderMode.capturingWord);
                    },
                    delay: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedOpacity(
          opacity: (_isAnalyzing || _readerMode != ReaderMode.reading || _isToolsMenuOpen) ? 1.0 : _fabOpacity,
          duration: const Duration(milliseconds: 300),
          child: MouseRegion(
            onEnter: (_) {
              _fabOpacityTimer?.cancel();
              setState(() => _fabOpacity = 1.0);
            },
            onExit: (_) {
              if (!_isToolsMenuOpen && !_isAnalyzing && _readerMode == ReaderMode.reading) {
                _onUserInteraction();
              }
            },
            child: FloatingActionButton(
              onPressed: _toggleToolsMenu,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: (_isAnalyzing || _readerMode != ReaderMode.reading)
                    ? const Icon(Icons.close_rounded, key: ValueKey('close'))
                    : AnimatedRotation(
                        turns: _isToolsMenuOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isToolsMenuOpen ? Icons.add : Icons.auto_fix_high,
                          key: const ValueKey('menu'),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  String _getAnalyzingMessage(AppLocalizations l10n) {
    if (_readerMode == ReaderMode.findingSynonyms) {
      return "Buscando sinónimos con IA...";
    } else if (_readerMode == ReaderMode.analyzing) {
      return "Analizando texto con IA...";
    }
    return l10n.creatingCardFor(_capturedWordForAI ?? '...');
  }

  String _getInstructionText(AppLocalizations l10n) {
    switch (_readerMode) {
      case ReaderMode.capturingWord:
        return l10n.promptSelectWord;
      case ReaderMode.capturingContext:
        final word = _capturedWordForAI ?? _pendingStudyData?['word'] ?? '...';
        
        // Determinar modo de estudio
        final bookMode = _book.studyMode;
        final globalMode = SettingsService.instance.studyMode;
        final isLearningMode = bookMode == 'learn_language' || (bookMode == null && globalMode == 'learning');

        if (isLearningMode) {
          return l10n.promptSelectContext(word); // "Selecciona la oración para: [palabra]"
        } else {
          return l10n.promptSelectContextVocab(word); // "Selecciona el contexto para: [palabra]"
        }
      case ReaderMode.analyzing:
        return l10n.promptSelectText;
      case ReaderMode.findingSynonyms:
        return l10n.promptSelectWord;
      default:
        return '';
    }
  }

  Widget _buildModernSpeedDialItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (delay * 50)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: onTap,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 4,
                  child: Icon(icon),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChapterView extends StatefulWidget {
  final ChapterData chapter;
  final String bookId;
  final int chapterIndex;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final TextAlign textAlign;
  final ReaderMode readerMode;
  final Function(String) onSelectionChanged;
  final Function(double) onProgressChanged;
  final Function(double) onSaveToStudy;
  final VoidCallback onUserInteraction;
  final bool isSelectingContext;
  final int selectionClearToken;
  final String? studyMode;

  const _ChapterView({
    super.key,
    required this.chapter,
    required this.bookId,
    required this.chapterIndex,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.textAlign,
    required this.readerMode,
    required this.onSelectionChanged,
    required this.onProgressChanged,
    required this.onSaveToStudy,
    required this.onUserInteraction,
    this.isSelectingContext = false,
    this.selectionClearToken = 0,
    this.studyMode,
  });

  @override
  State<_ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<_ChapterView> {
  late ScrollController _scrollController;
  Timer? _scrollSaveTimer;
  bool _isLoading = true; // Estado de carga para evitar saltos visuales
  double _savedOffset = 0.0;
  final FocusNode _selectionFocusNode = FocusNode();

  @override
  void didUpdateWidget(_ChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionClearToken != oldWidget.selectionClearToken) {
      _selectionFocusNode.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    
    // 1. Obtener offset guardado
    final key = 'scroll_${widget.bookId}_${widget.chapterIndex}';
    _savedOffset = SettingsService.instance.getDouble(key) ?? 0.0;
    
    // 2. Inicializar controller
    _scrollController = ScrollController(initialScrollOffset: _savedOffset);
    _scrollController.addListener(_onScroll);
    
    // 3. Timeout de seguridad para quitar el loading si tarda mucho
    Timer(const Duration(milliseconds: 800), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _onScroll(); // Intentar actualizar progreso una última vez
      }
    });

    // 4. Verificar carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollRestoration();
    });
  }

  @override
  void dispose() {
    _selectionFocusNode.dispose();
    _scrollSaveTimer?.cancel();
    _saveScrollPosition();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollRestoration() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Si ya tenemos contenido suficiente para restaurar la posición
    if (maxScroll >= _savedOffset) {
      if (_savedOffset > 0) {
        _scrollController.jumpTo(_savedOffset);
      }
      
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
      
      // Forzar actualización de progreso
      _updateProgress();
    } else {
      // Si el contenido aún es pequeño (cargando imágenes/fuentes), esperamos
      // El NotificationListener llamará a _onScroll/_checkScrollRestoration
    }
  }

  void _onScroll() {
    widget.onUserInteraction();
    if (_isLoading) {
      _checkScrollRestoration();
    } else {
      _updateProgress();
      
      // Debounce save
      if (_scrollSaveTimer?.isActive ?? false) _scrollSaveTimer!.cancel();
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
         _scrollSaveTimer = Timer(const Duration(seconds: 1), _saveScrollPosition);
      }
    }
  }

  String _getLabelForMode(ReaderMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ReaderMode.capturingWord:
        return l10n.actionConfirmWord;
      case ReaderMode.capturingContext:
        // Determinar modo de estudio
        final bookMode = widget.studyMode;
        final globalMode = SettingsService.instance.studyMode;
        final isLearningMode = bookMode == 'learn_language' || (bookMode == null && globalMode == 'learning');

        if (isLearningMode) {
          return l10n.actionConfirmContext; // "Confirmar oración"
        } else {
          return l10n.actionConfirmContextVocab; // "Confirmar contexto"
        }
      case ReaderMode.analyzing:
        return l10n.actionAnalyze;
      case ReaderMode.findingSynonyms:
        return l10n.actionSynonyms;
      case ReaderMode.reading:
        return l10n.saveCard;
    }
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    double progress = 0.0;
    if (maxScroll > 10) { 
      progress = currentScroll / maxScroll;
    }
    
    progress = progress.clamp(0.0, 1.0);
    widget.onProgressChanged(progress);
  }

  Future<void> _saveScrollPosition() async {
    final key = 'scroll_${widget.bookId}_${widget.chapterIndex}';
    try {
      if (_scrollController.hasClients) {
        await SettingsService.instance.setDouble(key, _scrollController.offset);
      }
    } catch (e) {
      debugPrint('Error saving scroll position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SelectionArea(
      focusNode: _selectionFocusNode,
      onSelectionChanged: (selection) {
        widget.onSelectionChanged(selection?.plainText ?? '');
      },
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems =
            editableTextState.contextMenuButtonItems;
        
        if (widget.readerMode != ReaderMode.reading) {
          buttonItems.insert(
            0,
            ContextMenuButtonItem(
              onPressed: () {
                editableTextState.hideToolbar();
                
                // CÁLCULO MEJORADO DE POSICIÓN
                double currentProgress = 0.0;
                if (_scrollController.hasClients) {
                  try {
                    final scrollOffset = _scrollController.offset;
                    final maxScroll = _scrollController.position.maxScrollExtent;
                    final viewportHeight = _scrollController.position.viewportDimension;
                    
                    // Intentar obtener la posición del toque
                    double touchYRelative = 0.5; // Default: centro del viewport
                    try {
                      final anchor = editableTextState.contextMenuAnchors.primaryAnchor;
                      touchYRelative = anchor.dy / viewportHeight; // Normalizado 0-1 dentro del viewport
                    } catch (e) {
                      debugPrint("No se pudo obtener anchor, usando centro");
                    }
                    
                    // CÁLCULO HÍBRIDO MEJORADO
                    double scrollProgress = 0.0;
                    double viewportSize = 0.0;
                    double touchOffset = 0.0;
                    
                    if (maxScroll > 0) {
                      // 1. Posición base del scroll
                      scrollProgress = scrollOffset / maxScroll;
                      
                      // 2. Ajuste fino basado en la posición del toque dentro del viewport
                      viewportSize = viewportHeight / (maxScroll + viewportHeight);
                      touchOffset = touchYRelative * viewportSize;
                      
                      // 3. Combinar ambos
                      currentProgress = scrollProgress + touchOffset;
                    } else {
                      // Documento corto que cabe en una pantalla
                      currentProgress = touchYRelative;
                    }
                    
                    currentProgress = currentProgress.clamp(0.0, 1.0);
                    
                  } catch (e) {
                    debugPrint("Error calculando posición: $e");
                    // Fallback: usar scroll básico
                    if (_scrollController.position.maxScrollExtent > 0) {
                      currentProgress = _scrollController.offset / 
                                      _scrollController.position.maxScrollExtent;
                    }
                  }
                }

                widget.onSaveToStudy(currentProgress);

              },
              label: _getLabelForMode(widget.readerMode, l10n),
            ),
          );
        }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      child: Stack(
        children: [
          // Contenido con opacidad animada
          AnimatedOpacity(
            opacity: _isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: NotificationListener<ScrollMetricsNotification>(

              onNotification: (metrics) {
                widget.onUserInteraction();
                if (_isLoading) {
                   _checkScrollRestoration();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  left: 24.0, 
                  right: 24.0, 
                  top: 100.0, 
                  bottom: 100.0 
                ),
                child: HtmlWidget(
                  widget.chapter.htmlContent,
                  key: ValueKey('html_${widget.chapterIndex}_${widget.textAlign}_${widget.fontFamily}_${widget.fontSize}'),
                  textStyle: GoogleFonts.getFont(
                    widget.fontFamily,
                    fontSize: widget.fontSize,
                    color: widget.textColor,
                    height: 1.6,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'p' || element.localName == 'div') {
                      return {
                        'text-align': widget.textAlign == TextAlign.justify ? 'justify !important' : 'left !important',
                      };
                    }
                    return null;
                  },
                  onTapUrl: (url) async {
                     if (url.contains('#')) {
                       PremiumToast.show(context, l10n.footnoteDevelopment);
                       return true; 
                     }
                     return false; 
                  },
                ),
              ),
            ),
          ),
          
          // Indicador de carga elegante
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadingChapter,
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
