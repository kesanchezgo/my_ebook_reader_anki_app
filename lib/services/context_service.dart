enum ContextMode {
  sentence,
  paragraph,
}

class ContextService {
  /// Extrae el contexto (oración o párrafo) alrededor de una palabra seleccionada.
  String extractContext(String word, String fullText, {ContextMode mode = ContextMode.sentence, int? selectionIndex}) {
    if (word.isEmpty || fullText.isEmpty) return "";

    // 1. Encontrar la posición de la palabra
    // Usamos RegExp para encontrar la palabra exacta y evitar coincidencias parciales
    // (ej. "ola" dentro de "hola")
    final wordRegExp = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    final matches = wordRegExp.allMatches(fullText);
    
    if (matches.isEmpty) {
      // Si no se encuentra como palabra completa, intentamos búsqueda simple
      final int wordIndex = fullText.indexOf(word);
      if (wordIndex == -1) return "";
      
      // Si encontramos por búsqueda simple, usamos ese índice
      return _expandBoundaries(fullText, wordIndex, wordIndex + word.length, mode);
    }

    RegExpMatch bestMatch = matches.first;

    // Lógica de proximidad
    if (selectionIndex != null) {
      int minDistance = (matches.first.start - selectionIndex).abs();
      
      for (final match in matches) {
        final distance = (match.start - selectionIndex).abs();
        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = match;
        }
      }
    }

    return _expandBoundaries(fullText, bestMatch.start, bestMatch.end, mode);
  }

  String _expandBoundaries(String fullText, int wordIndex, int wordEnd, ContextMode mode) {
    // 2. Definir delimitadores según el modo
    final RegExp delimiters = mode == ContextMode.sentence
        ? RegExp(r'[.?!。！？\n]') // Fin de oración
        : RegExp(r'[\n\r]');     // Fin de párrafo

    // 3. Expandir hacia la izquierda
    int start = wordIndex;
    while (start > 0) {
      final char = fullText[start - 1];
      if (delimiters.hasMatch(char)) {
        break;
      }
      start--;
    }

    // 4. Expandir hacia la derecha
    int end = wordEnd;
    while (end < fullText.length) {
      final char = fullText[end];
      if (delimiters.hasMatch(char)) {
        // Incluimos el delimitador si es puntuación, pero no si es salto de línea
        if (mode == ContextMode.sentence && char != '\n') {
          end++; 
        }
        break;
      }
      end++;
    }

    // 5. Extraer y limpiar
    String extracted = fullText.substring(start, end);
    return _cleanText(extracted);
  }

  /// Limpia el texto de referencias y espacios extra
  String _cleanText(String text) {
    var cleaned = text;

    // Eliminar referencias tipo [1], [12]
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+\]'), '');

    // Reemplazar saltos de línea y tabulaciones por espacios simples
    cleaned = cleaned.replaceAll(RegExp(r'[\n\r\t]'), ' ');

    // Eliminar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Eliminar espacios al inicio y final
    cleaned = cleaned.trim();

    // Eliminar puntuación "suelta" o guiones al inicio que hayan quedado por el corte
    // Ej: "- Hola" -> "Hola" (opcional, según preferencia, aquí lo dejamos limpio)
    // while (cleaned.isNotEmpty && (cleaned.startsWith('-') || cleaned.startsWith('—') || cleaned.startsWith('―'))) {
    //   cleaned = cleaned.substring(1).trim();
    // }

    // Nueva regex para quitar : , ; al final
    cleaned = cleaned.replaceAll(RegExp(r'[:;,]+$'), '');
    return cleaned.trim();
  }
}
