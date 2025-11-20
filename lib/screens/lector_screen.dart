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
import '../bloc/biblioteca_bloc.dart';
import '../bloc/biblioteca_event.dart';
import '../widgets/anki_edit_modal.dart';
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

  /// Extrae la oración completa con lógica inteligente para diálogos y longitud
  String _extractSentence(String word, String fullText) {
    if (word.isEmpty || fullText.isEmpty) return "";
    
    // Nota: Esto encuentra la primera ocurrencia.
    // Buscar la primera ocurrencia de la palabra como palabra completa usando RegExp
    final regExp = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    final match = regExp.firstMatch(fullText);
    if (match == null) return "";
    int wordIndex = match.start;

    // Definición de delimitadores
    final strongDelimiters = {'.', '?', '!', '\n'};
    final dialogueDelimiters = {'―', '—', '-'}; 
    final weakDelimiters = {',', ';'};
    
    int start = wordIndex;
    int end = wordIndex + word.length;
    
    // 1. Búsqueda hacia la IZQUIERDA
    int i = start - 1;
    while (i >= 0) {
      final char = fullText[i];
      
      if (strongDelimiters.contains(char)) {
        start = i + 1; // El inicio es después del punto/salto
        break;
      }
      
      if (dialogueDelimiters.contains(char)) {
        start = i; // Incluimos el guion de diálogo
        break;
      }
      
      if (weakDelimiters.contains(char)) {
        // Solo cortamos en coma si la distancia es mayor a 150 caracteres
        if ((wordIndex - i) > 150) {
          start = i + 1; // Cortamos después de la coma
          break;
        }
      }
      
      if (i == 0) start = 0;
      i--;
    }

    // 2. Búsqueda hacia la DERECHA
    i = end;
    while (i < fullText.length) {
      final char = fullText[i];
      
      if (strongDelimiters.contains(char)) {
        end = i + 1; // Incluimos el punto final
        break;
      }
      
      if (dialogueDelimiters.contains(char)) {
        end = i + 1; // Incluimos el guion de cierre
        break;
      }
      
      if (weakDelimiters.contains(char)) {
        // Solo cortamos en coma si la distancia es mayor a 150 caracteres
        if ((i - (wordIndex + word.length)) > 150) {
          end = i; // Excluimos la coma final
          break;
        }
      }
      
      i++;
      if (i == fullText.length) end = fullText.length;
    }
    
    // 3. Limpieza Final
    String extracted = fullText.substring(start, end).trim();
    
    // Eliminar puntuación "suelta" al inicio (comas, puntos y coma)
    while (extracted.isNotEmpty && RegExp(r'^[,;]').hasMatch(extracted)) {
      extracted = extracted.substring(1).trim();
    }
    
    return extracted;
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permite que el modal ocupe más espacio si es necesario
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 24.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Configuración de Lectura',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await SettingsService.instance.resetToDefaults();
                            _loadSettings();
                            setState(() {});
                            setModalState(() {});
                          },
                          child: Text('Restaurar', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Tamaño de fuente
                    Text('Tamaño de fuente: ${_fontSize.toInt()}', 
                      style: const TextStyle(color: Colors.grey)),
                    Slider(
                      value: _fontSize,
                      min: 14.0,
                      max: 32.0,
                      divisions: 18,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.grey[800],
                      onChanged: (value) {
                        setModalState(() => _fontSize = value);
                        setState(() => _fontSize = value);
                        SettingsService.instance.setFontSize(value);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tipo de fuente
                    const Text('Tipo de fuente', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _fontFamily,
                          isExpanded: true,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          items: ['Merriweather', 'Lato', 'Lora', 'Roboto Mono']
                              .map((font) => DropdownMenuItem(
                                    value: font,
                                    child: Text(font),
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
                    const Text('Alineación', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAlignButton(
                            'Justificado', 
                            TextAlign.justify, 
                            setModalState
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAlignButton(
                            'Izquierda', 
                            TextAlign.left, 
                            setModalState
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAlignButton(String label, TextAlign align, StateSetter setModalState) {
    final isSelected = _textAlign == align;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        setModalState(() => _textAlign = align);
        setState(() => _textAlign = align);
        SettingsService.instance.setTextAlign(align == TextAlign.justify ? 'justify' : 'left');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[800]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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
                      onSaveToAnki: () {
                        if (_currentSelection.isEmpty) {
                          PremiumToast.show(context, 'Selecciona una palabra primero', isError: true);
                          return;
                        }

                        final sentenceContext = _extractSentence(_currentSelection, chapters[index].plainText);

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => AnkiEditModal(
                            word: _currentSelection,
                            bookId: widget.book.id,
                            bookTitle: widget.book.title,
                            context: sentenceContext.isNotEmpty ? sentenceContext : chapters[index].plainText,
                          ),
                        );
                      },
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
                  // Botón flotante de acción rápida para Anki si hay selección
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
  final VoidCallback onSaveToAnki;

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
    required this.onSaveToAnki,
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
              widget.onSaveToAnki();
            },
            label: 'Guardar en Anki',
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