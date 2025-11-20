import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

/// Modelo de datos para un capítulo procesado (View Data vs Logic Data)
class ChapterData {
  final String title;
  final String htmlContent; // Con estilos inyectados e imágenes en Base64
  final String plainText;   // Texto limpio para buscar oraciones

  ChapterData({
    required this.title,
    required this.htmlContent,
    required this.plainText,
  });
}

class EpubService {
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

    return ChapterData(
      title: title,
      htmlContent: wrappedHtml,
      plainText: plainText,
    );
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
}
