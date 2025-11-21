import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:path/path.dart' as p;
import '../models/book.dart';
import 'local_storage_service.dart';

class DuplicateBookException implements Exception {
  final String message;
  DuplicateBookException(this.message);
  @override
  String toString() => message;
}

/// Modelo de datos para un capítulo procesado (View Data vs Logic Data)
class ChapterData {
  final String title;
  final String htmlContent; // Con estilos inyectados e imágenes en Base64
  final String plainText;   // Texto limpio para buscar oraciones
  final List<String> paragraphs; // Lista de párrafos atomizados
  final String css; // Estilos CSS extraídos del capítulo

  ChapterData({
    required this.title,
    required this.htmlContent,
    required this.plainText,
    required this.paragraphs,
    required this.css,
  });
}

class EpubService {
  /// Carga la información del libro desde el archivo EPUB
  Future<Book> loadBookInfo(File file) async {
    // 1. Generar ID único basado en la ruta absoluta
    final String uniqueId = file.absolute.path.hashCode.toString();

    // 2. Verificar duplicados
    final storage = await LocalStorageService.init();
    final books = await storage.getBooks();
    
    // Verificar si ya existe un libro con este ID (o ruta)
    if (books.any((b) => b.id == uniqueId || b.filePath == file.path)) {
      throw DuplicateBookException('El libro ya existe en la biblioteca.');
    }

    // 3. Leer metadatos del EPUB
    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);
    
    // Título
    String title = epubBook.Title ?? '';
    final filename = p.basenameWithoutExtension(file.path);
    
    // Si el título está vacío, es igual al nombre de archivo, O contiene guiones bajos (indicativo de nombre técnico)
    if (title.trim().isEmpty || title.trim() == filename || title.contains('_')) {
      // Preferimos el nombre del archivo limpio si el título interno parece "sucio"
      title = _beautifyFilename(filename);
    }
    
    // Autor
    String author = epubBook.Author ?? '';
    if (epubBook.AuthorList != null && epubBook.AuthorList!.isNotEmpty) {
       author = epubBook.AuthorList!.join(', ');
    }
    
    // Si no hay autor, intentamos buscar en el nombre del archivo si tiene formato "Autor - Título"
    if (author.trim().isEmpty) {
      if (filename.contains(' - ')) {
        final parts = filename.split(' - ');
        // Asumimos que la primera parte podría ser el autor si es corta
        if (parts.length >= 2 && parts[0].length < 40) {
          author = _beautifyFilename(parts[0]);
          // Si usamos el nombre de archivo para el autor, actualizamos el título con la segunda parte
          if (title == _beautifyFilename(filename)) {
             title = _beautifyFilename(parts.sublist(1).join(' '));
          }
        }
      }
    }
    // Si sigue vacío, lo dejamos vacío visualmente (no "Desconocido")

    // 4. Crear objeto Book
    return Book(
      id: uniqueId,
      title: title,
      author: author,
      filePath: file.path,
      fileType: 'epub',
      addedDate: DateTime.now(),
    );
  }

  /// Parsea el archivo EPUB y devuelve una lista de objetos ChapterData.
  Future<List<ChapterData>> loadChapters(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      
      List<ChapterData> chaptersData = [];
      
      // Recorrer capítulos y aplanar la estructura
      if (epubBook.Chapters != null) {
        for (var chapter in epubBook.Chapters!) {
          await _processChapter(chapter, epubBook, chaptersData);
        }
      }
      
      return chaptersData;
    } catch (e) {
      print('Error parseando EPUB: $e');
      return [
        ChapterData(
          title: 'Error',
          htmlContent: '<div id="chapter-content"><h1>Error al cargar el libro</h1><p>${e.toString()}</p></div>',
          plainText: 'Error al cargar el libro',
          paragraphs: ['<p>Error al cargar el libro: ${e.toString()}</p>'],
          css: '',
        )
      ];
    }
  }

  Future<void> _processChapter(EpubChapter chapter, EpubBook book, List<ChapterData> dataList) async {
    // Si el capítulo tiene contenido HTML, lo procesamos
    if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
      final chapterData = _createChapterData(chapter.Title ?? "Sin título", chapter.HtmlContent!, book);
      dataList.add(chapterData);
    }

    // Procesar subcapítulos recursivamente
    if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
      for (var subChapter in chapter.SubChapters!) {
        await _processChapter(subChapter, book, dataList);
      }
    }
  }

  /// Implementa la lógica de limpieza, separación de datos e inyección de imágenes
  ChapterData _createChapterData(String title, String rawHtml, EpubBook book) {
    // Parsear HTML para manipulación segura
    final document = html_parser.parse(rawHtml);
    
    // 1. Extraer Logic Data (Texto Plano)
    final String plainText = document.body?.text ?? "";

    // 2. Procesar Imágenes (Inyección Base64)
    final images = book.Content?.Images;
    if (images != null) {
      document.querySelectorAll('img').forEach((imgElement) {
        final src = imgElement.attributes['src'];
        if (src != null) {
          // Estrategia de búsqueda de imagen
          EpubByteContentFile? imageContent;
          
          // A. Búsqueda directa (si la ruta coincide exactamente)
          if (images.containsKey(src)) {
            imageContent = images[src];
          } 
          // B. Búsqueda por nombre de archivo (más robusta para rutas relativas)
          else {
            final filename = src.split('/').last; // ej: "cover.jpg"
            try {
              // Buscar cualquier clave que termine con este nombre de archivo
              // Esto soluciona problemas como "../Images/cover.jpg" vs "OEBPS/Images/cover.jpg"
              final key = images.keys.firstWhere(
                (k) => k.endsWith(filename), 
                orElse: () => ''
              );
              if (key.isNotEmpty) {
                imageContent = images[key];
              }
            } catch (e) {
              print('Error buscando imagen $src: $e');
            }
          }

          // Si encontramos la imagen, la convertimos a Base64
          if (imageContent != null) {
            final content = imageContent.Content;
            if (content != null) {
              final base64 = base64Encode(content);
              final mimeType = _getMimeType(src);
              
              // Reemplazar src con data URI
              imgElement.attributes['src'] = 'data:$mimeType;base64,$base64';
              
              // Asegurar que la imagen no rompa el layout
              imgElement.attributes['style'] = 'max-width: 100%; height: auto; display: block; margin: 10px auto;';
            }
          }
        }
      });
    }

    // 3. Preparar View Data (HTML Renderizable)
    
    // Eliminar scripts por seguridad
    document.querySelectorAll('script').forEach((element) => element.remove());
    
    // Obtener el contenido del body para envolverlo
    // Nota: html_parser preserva atributos como id y name en <a>, necesarios para notas al pie.
    final bodyContent = document.body?.innerHtml ?? "";
    
    // Envolver en div con id="chapter-content"
    final wrappedHtml = '<div id="chapter-content">$bodyContent</div>';

    // 4. Generar lista de párrafos atomizados
    final paragraphs = _splitHtmlContent(document);

    // 5. Extraer CSS
    final css = _extractCss(document, book);

    return ChapterData(
      title: title,
      htmlContent: wrappedHtml,
      plainText: plainText,
      paragraphs: paragraphs,
      css: css,
    );
  }

  String _extractCss(dom.Document document, EpubBook book) {
    final StringBuffer cssBuffer = StringBuffer();
    final cssFiles = book.Content?.Css;

    // 1. Extraer estilos de <link rel="stylesheet">
    document.querySelectorAll('link[rel="stylesheet"]').forEach((link) {
      final href = link.attributes['href'];
      if (href != null && cssFiles != null) {
        // Resolver ruta relativa o absoluta
        // Intentar encontrar el archivo CSS en el mapa de recursos
        // Las claves en cssFiles suelen ser rutas completas como "OEBPS/Styles/style.css"
        // El href puede ser "../Styles/style.css" o "style.css"
        
        // Estrategia simple: buscar por nombre de archivo
        final filename = href.split('/').last;
        try {
          final key = cssFiles.keys.firstWhere(
            (k) => k.endsWith(filename), 
            orElse: () => ''
          );
          
          if (key.isNotEmpty) {
            final cssContent = cssFiles[key]?.Content;
            if (cssContent != null) {
              cssBuffer.writeln(cssContent);
            }
          }
        } catch (e) {
          print('Error extrayendo CSS $href: $e');
        }
      }
    });

    // 2. Extraer estilos de <style>
    document.querySelectorAll('style').forEach((style) {
      cssBuffer.writeln(style.text);
    });

    // Reemplazar selectores 'body' por '.epub-body' para que apliquen dentro del widget
    // Usamos una regex que busca 'body' precedido por inicio, espacio, coma o combinadores
    String css = cssBuffer.toString();
    css = css.replaceAll(RegExp(r'(^|[\s,>+~])body\b', caseSensitive: false), r'$1.epub-body');
    
    return css;
  }

  List<String> _splitHtmlContent(dom.Document document) {
    final List<String> result = [];
    final body = document.body;
    if (body == null) return [];

    // Pasar el body como contexto inicial, pero no envolveremos en body en el resultado final
    // para evitar duplicidad de tags body.
    _processContainer(body, result, []);
    return result;
  }

  void _processContainer(dom.Element container, List<String> result, List<dom.Element> parents) {
    List<dom.Node> inlineAccumulator = [];

    void flushAccumulator() {
      if (inlineAccumulator.isEmpty) return;
      
      final textContent = inlineAccumulator.map((n) => n.text).join();
      if (textContent.trim().isEmpty) {
        inlineAccumulator.clear();
        return;
      }

      String htmlContent = inlineAccumulator.map((n) {
        if (n is dom.Element) return n.outerHtml;
        if (n is dom.Text) return n.text;
        return "";
      }).join();
      
      // No envolver en p forzosamente. Si el contenido original no tenía p, no debemos inventarlo.
      // Esto evita márgenes dobles o estilos incorrectos cuando el texto estaba directo en un div.
      String wrapped = htmlContent;
      
      // Aplicar jerarquía de padres para preservar selectores CSS
      // IMPORTANTE: Incluir TODOS los padres, incluso divs sin atributos, 
      // para que los selectores CSS basados en estructura (ej: div > p) funcionen.
      for (var parent in parents.reversed) {
         final attrs = parent.attributes.entries.map((e) => '${e.key}="${e.value}"').join(' ');
         wrapped = '<${parent.localName} $attrs>$wrapped</${parent.localName}>';
      }
      
      result.add(wrapped);
      inlineAccumulator.clear();
    }

    for (var node in container.nodes) {
      if (node is dom.Element && _isBlock(node)) {
        flushAccumulator(); 
        
        if (_hasBlockChildren(node)) {
          // Añadir este nodo a la lista de padres y recursar
          final newParents = List<dom.Element>.from(parents)..add(node);
          _processContainer(node, result, newParents); 
        } else {
          // Bloque hoja. Envolver en sus padres.
          String wrapped = node.outerHtml;
          for (var parent in parents.reversed) {
             final attrs = parent.attributes.entries.map((e) => '${e.key}="${e.value}"').join(' ');
             wrapped = '<${parent.localName} $attrs>$wrapped</${parent.localName}>';
          }
          result.add(wrapped);
        }
      } else {
        inlineAccumulator.add(node);
      }
    }
    flushAccumulator(); 
  }

  bool _isBlock(dom.Element e) {
    final blockTags = [
      'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 
      'li', 'blockquote', 'pre', 'hr', 'table', 'ul', 'ol', 
      'section', 'article', 'header', 'footer'
    ];
    return blockTags.contains(e.localName);
  }
  
  bool _hasBlockChildren(dom.Element e) {
    // No dividir estructuras complejas que dependen de su contenedor padre
    if (['ul', 'ol', 'table', 'pre', 'figure'].contains(e.localName)) return false;
    return e.children.any((c) => _isBlock(c));
  }

  String _getMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Extrae la imagen de portada del archivo EPUB
  Future<Uint8List?> getCoverImage(File epubFile) async {
    try {
      final bytes = await epubFile.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      
      // 1. Intentar obtener desde la propiedad coverImage
      if (epubBook.CoverImage != null) {
        // EpubReader a veces devuelve Image, pero necesitamos bytes.
        // La librería epubx devuelve Image (de package:image) en CoverImage.
        // Sin embargo, para evitar dependencias extra de codificación,
        // busquemos en Content.Images si es posible, o usemos la propiedad si es bytes.
        // Revisando la librería epubx: CoverImage es `Image?`.
        // Es mejor buscar el archivo crudo en Content.Images para obtener Uint8List directamente.
        
        // Buscamos en metadatos el item con id "cover" o similar
        // O iteramos las imágenes buscando la que parece ser la portada.
      }

      // Estrategia alternativa: Buscar en Content.Images
      // Muchas veces la portada es la primera imagen o tiene "cover" en el nombre.
      if (epubBook.Content?.Images != null && epubBook.Content!.Images!.isNotEmpty) {
        // Buscar por nombre "cover"
        for (var key in epubBook.Content!.Images!.keys) {
          if (key.toLowerCase().contains('cover')) {
             final content = epubBook.Content!.Images![key]!.Content;
             if (content != null) {
               return Uint8List.fromList(content);
             }
          }
        }
        // Si no, devolver la primera imagen grande (opcional, por ahora devolvemos la primera)
        // return epubBook.Content!.Images!.values.first.Content;
      }
      
      return null;
    } catch (e) {
      print('Error extrayendo portada: $e');
      return null;
    }
  }

  String _beautifyFilename(String filename) {
    // 1. Reemplazar caracteres especiales por espacios
    String cleanName = filename.replaceAll(RegExp(r'[_\-\.]'), ' ');
    
    // 2. Eliminar palabras comunes de nombres de archivo (case insensitive)
    cleanName = cleanName.replaceAll(RegExp(r'\b(trad|epub|v1|v2|v3|final|corregido)\b', caseSensitive: false), '');
    
    // 3. Capitalizar cada palabra (Title Case)
    cleanName = cleanName.split(' ').where((word) => word.isNotEmpty).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return cleanName.trim();
  }
}
