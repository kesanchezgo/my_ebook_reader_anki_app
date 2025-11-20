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
  int _readingSeconds = 0;
  
  // Progress
  double _chapterProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chaptersFuture = EpubService().loadChapters(File(widget.book.filePath));
    _loadSettings();
    _loadProgress();
    _startReadingTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveReadingTime();
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
      _readingSeconds = prefs.getInt('reading_time_${widget.book.id}') ?? 0;

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
      if (mounted) {
        context.read<BibliotecaBloc>().add(UpdateBook(widget.book.copyWith(currentPage: index)));
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }
  
  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _readingSeconds++;
      });
      // Guardar cada minuto para no saturar
      if (_readingSeconds % 60 == 0) {
        _saveReadingTime();
      }
    });
  }
  
  Future<void> _saveReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reading_time_${widget.book.id}', _readingSeconds);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatReadingTime() {
    final duration = Duration(seconds: _readingSeconds);
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
                          child: const Text('Restaurar', style: TextStyle(color: Colors.blue)),
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
                      activeColor: Colors.blue,
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
                    
                    // Tema
                    const Text('Tema', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: SettingsService.instance.appThemes.values.map((theme) {
                        return _buildThemeButton(
                          theme,
                          setModalState
                        );
                      }).toList(),
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
    return GestureDetector(
      onTap: () {
        setModalState(() => _textAlign = align);
        setState(() => _textAlign = align);
        SettingsService.instance.setTextAlign(align == TextAlign.justify ? 'justify' : 'left');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[800]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(AppTheme theme, StateSetter setModalState) {
    final isSelected = _backgroundColor == theme.backgroundColor;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _backgroundColor = theme.backgroundColor;
          _textColor = theme.textColor;
        });
        setState(() {
          _backgroundColor = theme.backgroundColor;
          _textColor = theme.textColor;
        });
        SettingsService.instance.setThemeId(theme.id);
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            theme.name.split(' ').first,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _readingTimer?.cancel();
    _saveReadingTime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      _chapterProgress = 0.0; // Reset visual progress on chapter change
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
                      onProgressChanged: (progress) {
                        // Actualizar progreso solo si cambia significativamente para evitar rebuilds excesivos
                        if ((progress - _chapterProgress).abs() > 0.01) {
                          // Usamos addPostFrameCallback para evitar setState durante build/layout
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _chapterProgress = progress);
                          });
                        }
                      },
                      onSaveToAnki: () {
                        if (_currentSelection.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecciona una palabra primero')),
                          );
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
              backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _showSettingsModal,
                ),
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    // TODO: Implementar índice
                  },
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
              color: const Color(0xFF1E1E1E).withOpacity(0.95),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _formatReadingTime(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LinearProgressIndicator(
                          value: _chapterProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          minHeight: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_chapterProgress * 100).toInt()}% del capítulo',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón flotante de acción rápida para Anki si hay selección
                  if (_currentSelection.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
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
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollSaveTimer;

  @override
  void initState() {
    super.initState();
    _restoreScrollPosition();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollSaveTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'scroll_${widget.bookId}_${widget.chapterIndex}';
    final savedOffset = prefs.getDouble(key);
    
    if (savedOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(savedOffset);
        }
      });
    }
  }

  void _onScroll() {
    // Calcular progreso
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (maxScroll > 0) {
        widget.onProgressChanged(currentScroll / maxScroll);
      }
    }

    // Debounce save
    if (_scrollSaveTimer?.isActive ?? false) _scrollSaveTimer!.cancel();
    _scrollSaveTimer = Timer(const Duration(seconds: 1), _saveScrollPosition);
  }

  Future<void> _saveScrollPosition() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'scroll_${widget.bookId}_${widget.chapterIndex}';
    await prefs.setDouble(key, _scrollController.offset);
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
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 24.0, 
          right: 24.0, 
          top: 100.0, // Espacio para AppBar (kToolbarHeight + Status + Padding)
          bottom: 100.0 // Espacio para Footer
        ),
        child: HtmlWidget(
          widget.chapter.htmlContent,
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
             // Manejo de notas al pie y anclas
             if (url.contains('#')) {
               // TODO: Implementar navegación real a notas (requiere parsing complejo de IDs)
               // Por ahora, evitamos el crash y notificamos al usuario
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Nota al pie: Navegación en desarrollo'),
                   duration: Duration(seconds: 1),
                 ),
               );
               return true; // Consumir el evento para evitar abrir navegador
             }
             return false; // Dejar pasar enlaces externos normales
          },
        ),
      ),
    );
  }
}
