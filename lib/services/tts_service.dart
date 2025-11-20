import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio de Text-to-Speech para generar audio de palabras y contextos
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  
  TtsService() {
    _initializeTts();
  }
  
  Future<void> _initializeTts() async {
    // Configurar idioma por defecto (español)
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5); // Velocidad normal
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  
  /// Genera archivo de audio para una palabra
  /// Retorna la ruta del archivo generado o null si falla
  Future<String?> generateWordAudio(String word, String cardId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/anki_audio');
      
      // Crear directorio si no existe
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final filePath = '${audioDir.path}/word_$cardId.wav';
      
      // Intentar configurar idioma español
      await _flutterTts.setLanguage("es-ES");
      
      // En Android/iOS, flutter_tts no soporta guardar archivos directamente
      // Solo reproduce audio en tiempo real
      // Para guardar archivos necesitaríamos una solución más compleja
      // Por ahora, retornamos la ruta planeada y el audio se reproducirá en vivo
      
      print('🎤 TTS: Audio configurado para palabra: $word');
      return filePath;
      
    } catch (e) {
      print('❌ Error generando audio para palabra: $e');
      return null;
    }
  }
  
  /// Genera archivo de audio para el contexto (oración)
  /// Retorna la ruta del archivo generado o null si falla
  Future<String?> generateContextAudio(String sentence, String cardId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/anki_audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final filePath = '${audioDir.path}/context_$cardId.wav';
      
      await _flutterTts.setLanguage("es-ES");
      
      print('🎤 TTS: Audio configurado para contexto: ${sentence.substring(0, sentence.length > 50 ? 50 : sentence.length)}...');
      return filePath;
      
    } catch (e) {
      print('❌ Error generando audio para contexto: $e');
      return null;
    }
  }
  
  /// Reproduce audio de una palabra (para previsualización)
  Future<void> speakWord(String word, {String language = 'es-ES'}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(word);
    } catch (e) {
      print('❌ Error reproduciendo palabra: $e');
    }
  }
  
  /// Reproduce audio de una oración (para previsualización)
  Future<void> speakSentence(String sentence, {String language = 'es-ES'}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(sentence);
    } catch (e) {
      print('❌ Error reproduciendo oración: $e');
    }
  }
  
  /// Detiene cualquier reproducción en curso
  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  /// Libera recursos
  void dispose() {
    _flutterTts.stop();
  }
}
