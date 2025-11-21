import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/study_card.dart';

/// Servicio para exportar tarjetas de estudio a formato CSV
class ExportService {
  
  /// Exporta una lista de tarjetas a formato CSV
  /// Retorna la ruta del archivo generado
  Future<String> exportToCSV(List<StudyCard> cards) async {
    try {
      // Preparar datos para CSV
      List<List<String>> rows = [];
      
      // Header con los 6 campos de Anki
      rows.add([
        'Word',
        'Definition',
        'Sentence',
        'Audio Path',
        'Book Title',
        'Created At',
      ]);
      
      // Agregar cada tarjeta como fila
      for (var card in cards) {
        rows.add([
          card.word,
          card.definition,
          card.context,
          card.audioPath ?? '',
          card.fuente,
          card.createdAt.toIso8601String(),
        ]);
      }
      
      // Convertir a CSV
      String csv = const ListToCsvConverter().convert(rows);
      
      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/study_cards_export_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csv);
      
      print('✅ CSV exportado: $filePath');
      return filePath;
      
    } catch (e) {
      print('❌ Error exportando a CSV: $e');
      rethrow;
    }
  }
  
  /// Comparte el archivo CSV usando el sistema nativo de compartir
  Future<void> shareCSV(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado: $filePath');
      }
      
      // Usar share_plus para compartir el archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Tarjetas de Estudio - Exportación',
        text: 'Tarjetas de vocabulario para importar en Anki',
      );
      
      print('✅ Archivo compartido: $filePath');
      
    } catch (e) {
      print('❌ Error compartiendo archivo: $e');
      rethrow;
    }
  }
  
  /// Exporta y comparte en un solo paso
  Future<void> exportAndShare(List<StudyCard> cards) async {
    if (cards.isEmpty) {
      throw Exception('No hay tarjetas para exportar');
    }
    
    final filePath = await exportToCSV(cards);
    await shareCSV(filePath);
  }
  
  /// Genera formato de texto para importación manual en Anki
  /// Retorna un String con el formato: palabra;definición;oración
  String generateAnkiText(List<StudyCard> cards) {
    final buffer = StringBuffer();
    
    for (var card in cards) {
      // Formato: palabra;definición;oración;fuente
      buffer.writeln('${card.word};${card.definition};${card.context};${card.fuente}');
    }
    
    return buffer.toString();
  }
  
  /// Obtiene estadísticas de las tarjetas para el reporte de exportación
  Map<String, dynamic> getExportStats(List<StudyCard> cards) {
    if (cards.isEmpty) {
      return {
        'total': 0,
        'books': 0,
        'withAudio': 0,
        'withoutAudio': 0,
      };
    }
    
    final uniqueBooks = cards.map((c) => c.bookId).toSet().length;
    final withAudio = cards.where((c) => c.audioPath != null && c.audioPath!.isNotEmpty).length;
    
    return {
      'total': cards.length,
      'books': uniqueBooks,
      'withAudio': withAudio,
      'withoutAudio': cards.length - withAudio,
    };
  }
}
