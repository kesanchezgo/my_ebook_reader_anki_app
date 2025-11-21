import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../services/epub_service.dart';
import '../services/local_storage_service.dart';
import '../services/settings_service.dart';
import '../services/context_service.dart';
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../widgets/study_edit_modal.dart';
import '../widgets/premium_toast.dart';

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
  
  // Estado temporal para selección manual de contexto
  Map<String, dynamic>? _pendingStudyData;
  
  final ContextService _contextService = ContextService();

  @override
  void initState() {
    super.initState();
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
    return widget.book.copyWith(
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
        final updatedBook = widget.book.copyWith(
          currentPage: index,
          progressPercentage: _globalProgress * 100,
        );
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
                            'Ajustes',
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
                          'Restaurar', 
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
                    'Tamaño de texto',
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
                    'Tipografía',
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
                    'Alineación',
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
                            'Justificado', 
                            TextAlign.justify, 
                            Icons.format_align_justify_rounded,
                            setModalState,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildAlignButton(
                            'Izquierda', 
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
                  return Center(child: Text('Error cargando libro: ${snapshot.error}', style: TextStyle(color: _textColor)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No se pudo cargar el contenido del libro.', style: TextStyle(color: _textColor)));
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
                      chapter: chapters[index],
                      bookId: widget.book.id,
                      chapterIndex: index,
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                      textColor: _textColor,
                      textAlign: _textAlign,
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
                      onSaveToStudy: () async {
                        if (_currentSelection.isEmpty) {
                          PremiumToast.show(context, 'Selecciona una palabra primero', isError: true);
                          return;
                        }

                        String initialContext;
                        String initialWord = _currentSelection;
                        String initialDefinition = '';
                        String initialExample = '';

                        if (_pendingStudyData != null) {
                          // Modo selección manual: la selección actual ES el contexto
                          initialContext = _currentSelection;
                          // Restaurar datos previos
                          initialWord = _pendingStudyData!['word'] ?? '';
                          initialDefinition = _pendingStudyData!['definition'] ?? '';
                          initialExample = _pendingStudyData!['example'] ?? '';
                          // Limpiar estado pendiente
                          setState(() => _pendingStudyData = null);
                        } else {
                          // Modo normal: extracción automática usando ContextService
                          // TODO: Permitir configurar ContextMode desde ajustes del libro
                          initialContext = _contextService.extractContext(
                            _currentSelection, 
                            chapters[index].plainText,
                            mode: ContextMode.paragraph
                          );
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
                            context: initialContext.isNotEmpty ? initialContext : chapters[index].plainText,
                            initialDefinition: initialDefinition,
                            initialExample: initialExample,
                          ),
                        );

                        // Manejar solicitud de contexto manual
                        if (result != null && result is Map && result['action'] == 'manual_context') {
                          setState(() {
                            _pendingStudyData = result['formData'];
                          });
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
                              'Capítulo ${_currentChapterIndex + 1} de $totalChapters • ${(_chapterProgress * 100).toInt()}%',
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 10),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón flotante de acción rápida para guardar si hay selección
                  if (_currentSelection.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                         // Trigger save logic via callback or direct call if possible
                         // Since logic is in PageView builder, we might need a global key or similar
                         // For simplicity, we rely on the context menu, but this is a nice visual cue
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Panel de Selección de Contexto Manual
          if (_pendingStudyData != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                elevation: 8,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.format_quote_rounded, 
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Seleccionando contexto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selecciona el texto y pulsa "Confirmar Contexto"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() => _pendingStudyData = null);
                        },
                        tooltip: 'Cancelar',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
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
  final Function(String) onSelectionChanged;
  final Function(double) onProgressChanged;
  final VoidCallback onSaveToStudy;
  final bool isSelectingContext;

  const _ChapterView({
    required this.chapter,
    required this.bookId,
    required this.chapterIndex,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.textAlign,
    required this.onSelectionChanged,
    required this.onProgressChanged,
    required this.onSaveToStudy,
    this.isSelectingContext = false,
  });

  @override
  State<_ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<_ChapterView> {
  late ScrollController _scrollController;
  Timer? _scrollSaveTimer;
  bool _isLoading = true; // Estado de carga para evitar saltos visuales
  double _savedOffset = 0.0;

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
    return SelectionArea(
      onSelectionChanged: (selection) {
        widget.onSelectionChanged(selection?.plainText ?? '');
      },
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems =
            editableTextState.contextMenuButtonItems;
        
        buttonItems.insert(
          0,
          ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();
              widget.onSaveToStudy();
            },
            label: widget.isSelectingContext ? 'Confirmar Contexto' : 'Guardar Tarjeta',
          ),
        );

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
                       PremiumToast.show(context, 'Nota al pie: Navegación en desarrollo');
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
                    'Cargando capítulo...',
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