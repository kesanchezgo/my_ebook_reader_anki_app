enum ContextMode {
  sentence,
  paragraph,
}

class ContextService {
  /// Extrae el contexto (oración o párrafo) alrededor de una palabra seleccionada.
  String extractContext(String word, String fullText, {ContextMode mode = ContextMode.sentence, double? scrollPercentage}) {
    if (word.isEmpty || fullText.isEmpty) return "";

    final escapedWord = RegExp.escape(word);
    final matches = RegExp(r'\b' + escapedWord + r'\b', caseSensitive: false).allMatches(fullText);

    if (matches.isEmpty) return "";

    RegExpMatch bestMatch = matches.first;

    if (scrollPercentage != null) {
      // CLAMP: Asegurar rango válido 0.0 - 1.0
      final clampedScroll = scrollPercentage.clamp(0.0, 1.0);
      
      // LÓGICA GEOGRÁFICA: Convertir scroll a posición de caracter
      // Si el texto tiene 1000 chars y scroll es 50%, buscamos cerca del char 500.
      final int targetCharIndex = (fullText.length * clampedScroll).round();

      // Buscar el vecino más cercano por distancia de caracteres
      int minDistance = (matches.first.start - targetCharIndex).abs();

      for (final match in matches) {
        final distance = (match.start - targetCharIndex).abs();
        
        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = match;
        } else {
          // Optimización: Como los matches están ordenados, si la distancia empieza a crecer,
          // ya nos alejamos del punto óptimo y podemos detener el bucle.
          // (Opcional, pero mejora rendimiento en palabras muy frecuentes)
          // break; 
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
