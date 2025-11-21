enum ContextMode {
  sentence,
  paragraph,
}

class ContextService {
  String extractContext({
    required String word,
    required String fullText,
    ContextMode mode = ContextMode.sentence,
    double? scrollPercentage,
  }) {
    if (word.isEmpty || fullText.isEmpty) return "";

    // 🔍 DEBUG: Imprimir información
    print("=== DEBUG CONTEXT SERVICE ===");
    print("Palabra buscada: '$word'");
    print("Longitud texto completo: ${fullText.length}");
    print("ScrollPercentage recibido: $scrollPercentage");
    
    final escapedWord = RegExp.escape(word);
    final List<RegExpMatch> matches = RegExp(
      r'\b' + escapedWord + r'\b',
      caseSensitive: false,
    ).allMatches(fullText).toList();

    print("Total de coincidencias encontradas: ${matches.length}");
    
    if (matches.isEmpty) {
      print("❌ No se encontraron coincidencias");
      return "";
    }

    // Imprimir todas las posiciones
    for (int i = 0; i < matches.length && i < 10; i++) {
      final m = matches[i];
      final context = fullText.substring(
        (m.start - 30).clamp(0, fullText.length),
        (m.end + 30).clamp(0, fullText.length)
      ).replaceAll('\n', ' ');
      print("Match $i: posición ${m.start} - \"...$context...\"");
    }

    RegExpMatch bestMatch = matches.first;

    if (scrollPercentage != null) {
      final clampedScroll = scrollPercentage.clamp(0.0, 1.0);
      final docLength = fullText.length;
      final centerPos = (docLength * clampedScroll).round();
      
      print("\n📍 Posición estimada del scroll: $centerPos");
      print("Texto en esa posición: \"${fullText.substring((centerPos-20).clamp(0, fullText.length), (centerPos+20).clamp(0, fullText.length)).replaceAll('\n', ' ')}\"");

      final windowSize = (docLength * 0.10).round();
      final windowStart = (centerPos - windowSize).clamp(0, docLength);
      final windowEnd = (centerPos + windowSize).clamp(0, docLength);
      
      print("Ventana de búsqueda: [$windowStart - $windowEnd] (tamaño: ${windowSize * 2})");

      final matchesInWindow = matches
          .where((match) => match.start >= windowStart && match.start <= windowEnd)
          .toList();
      
      print("Matches dentro de ventana: ${matchesInWindow.length}");

      if (matchesInWindow.isEmpty) {
        print("⚠️ No hay matches en ventana, usando el más cercano");
        bestMatch = _findClosestMatch(matches, centerPos);
        print("Match seleccionado (fallback): posición ${bestMatch.start}");
      } else {
        RegExpMatch? selectedMatch;
        double bestScore = double.infinity;

        for (final match in matchesInWindow) {
          final distance = (match.start - centerPos).abs().toDouble();
          final score = match.start >= centerPos ? distance * 0.7 : distance * 1.0;
          final direction = match.start >= centerPos ? "adelante" : "atrás";
          
          print("  Evaluando pos ${match.start}: distancia=$distance, score=$score ($direction)");
          
          if (score < bestScore) {
            bestScore = score;
            selectedMatch = match;
          }
        }

        bestMatch = selectedMatch ?? matches.first;
        print("✅ Match seleccionado: posición ${bestMatch.start} (score: $bestScore)");
      }
    } else {
      print("⚠️ scrollPercentage es NULL, usando primer match");
    }

    final result = _expandBoundaries(fullText, bestMatch.start, bestMatch.end, mode);
    print("📝 Contexto extraído: \"$result\"");
    print("=== FIN DEBUG ===\n");
    
    return result;
  }


  /// Encuentra el mejor match usando ventana de búsqueda y scoring con sesgo adelante
  RegExpMatch _findMatchByScrollImproved({
    required String fullText,
    required List<RegExpMatch> matches,
    required double scrollPercentage,
  }) {
    final clampedScroll = scrollPercentage.clamp(0.0, 1.0);
    final docLength = fullText.length;
    final centerPos = (docLength * clampedScroll).round();

    // Definir ventana de búsqueda (±10% del documento)
    final windowSize = (docLength * 0.10).round();
    final windowStart = (centerPos - windowSize).clamp(0, docLength);
    final windowEnd = (centerPos + windowSize).clamp(0, docLength);

    // Filtrar matches dentro de la ventana
    final matchesInWindow = matches
        .where((match) => match.start >= windowStart && match.start <= windowEnd)
        .toList();

    if (matchesInWindow.isEmpty) {
      // Fallback: buscar el más cercano de todos
      return _findClosestMatch(matches, centerPos);
    }

    // De los matches en la ventana, elegir usando scoring con sesgo adelante
    RegExpMatch? bestMatch;
    double bestScore = double.infinity;

    for (final match in matchesInWindow) {
      final distance = (match.start - centerPos).abs().toDouble();

      // Sesgo hacia adelante: 30% de descuento para matches futuros
      final score = match.start >= centerPos
          ? distance * 0.7 // Matches adelante son preferidos
          : distance * 1.0; // Matches atrás sin descuento

      if (score < bestScore) {
        bestScore = score;
        bestMatch = match;
      }
    }

    return bestMatch ?? matches.first;
  }

  /// Busca el match más cercano a una posición (fallback)
  RegExpMatch _findClosestMatch(List<RegExpMatch> matches, int targetPosition) {
    RegExpMatch closest = matches.first;
    double minDistance = (matches.first.start - targetPosition).abs().toDouble();

    for (final match in matches) {
      final distance = (match.start - targetPosition).abs().toDouble();
      if (distance < minDistance) {
        minDistance = distance;
        closest = match;
      }
    }

    return closest;
  }

  String _expandBoundaries(
      String fullText, int wordIndex, int wordEnd, ContextMode mode) {
    // Definir delimitadores según el modo
    final RegExp delimiters = mode == ContextMode.sentence
        ? RegExp(r'[.?!。！？\n]') // Fin de oración
        : RegExp(r'[\n\r]'); // Fin de párrafo

    // Expandir hacia la izquierda
    int start = wordIndex;
    while (start > 0) {
      final char = fullText[start - 1];
      if (delimiters.hasMatch(char)) {
        break;
      }
      start--;
    }

    // Expandir hacia la derecha
    int end = wordEnd;
    while (end < fullText.length) {
      final char = fullText[end];
      if (delimiters.hasMatch(char)) {
        // Incluir puntuación pero no saltos de línea
        if (mode == ContextMode.sentence && char != '\n') {
          end++;
        }
        break;
      }
      end++;
    }

    // Extraer y limpiar
    String extracted = fullText.substring(start, end);
    return _cleanText(extracted);
  }

  /// Limpia el texto de referencias y espacios extra
  String _cleanText(String text) {
    var cleaned = text;

    // Eliminar referencias tipo [1], [12]
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+\]'), '');

    // Reemplazar saltos de línea y tabulaciones por espacios
    cleaned = cleaned.replaceAll(RegExp(r'[\n\r\t]'), ' ');

    // Eliminar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Eliminar espacios al inicio y final
    cleaned = cleaned.trim();

    // Eliminar puntuación final suelta
    cleaned = cleaned.replaceAll(RegExp(r'[:;,]+$'), '');

    return cleaned.trim();
  }
}
