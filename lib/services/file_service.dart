import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

/// Servicio para gestionar archivos y operaciones de importación
class FileService {
  /// Obtiene el directorio de documentos de la aplicación
  Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Permite al usuario seleccionar un archivo EPUB
  Future<FilePickerResult?> pickBookFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: false,
      );

      return result;
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      return null;
    }
  }

  /// Copia un archivo al directorio de la aplicación
  Future<String?> copyFileToAppDirectory(String sourcePath, String fileName) async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      
      // Crear directorio si no existe
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final newFile = File('${booksDir.path}/$fileName');
      final sourceFile = File(sourcePath);

      // Copiar el archivo
      await sourceFile.copy(newFile.path);
      
      return newFile.path;
    } catch (e) {
      print('Error al copiar archivo: $e');
      return null;
    }
  }

  /// Elimina un archivo del directorio de la aplicación
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  /// Obtiene el nombre del archivo desde una ruta
  String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Obtiene la extensión del archivo
  String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Verifica si un archivo existe
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
