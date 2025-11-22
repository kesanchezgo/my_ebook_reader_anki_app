import 'package:equatable/equatable.dart';

/// Modelo que representa un libro en la biblioteca
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String fileType; // 'pdf' o 'epub'
  final DateTime addedDate;
  final int currentPage;
  final int totalPages;
  final String? coverImage; // Path a la imagen de portada (opcional)
  final double progressPercentage; // Progreso global exacto (0.0 - 100.0)
  final String? language; // Idioma detectado (ej: 'es', 'en')
  final String? studyMode; // 'read_only', 'native_vocab', 'learn_language'
  final String? targetLanguage; // Idioma objetivo para traducción (ej: 'es')

  const Book({
    required this.id,
    required this.title,
    this.author = 'Autor Desconocido',
    required this.filePath,
    required this.fileType,
    required this.addedDate,
    this.currentPage = 0,
    this.totalPages = 0,
    this.coverImage,
    this.progressPercentage = 0.0,
    this.language,
    this.studyMode,
    this.targetLanguage,
  });

  /// Crea una copia del libro con los campos especificados modificados
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? fileType,
    DateTime? addedDate,
    int? currentPage,
    int? totalPages,
    String? coverImage,
    double? progressPercentage,
    String? language,
    String? studyMode,
    String? targetLanguage,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      addedDate: addedDate ?? this.addedDate,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      coverImage: coverImage ?? this.coverImage,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      language: language ?? this.language,
      studyMode: studyMode ?? this.studyMode,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  /// Convierte el libro a un Map para guardarlo en shared_preferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'fileType': fileType,
      'addedDate': addedDate.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'coverImage': coverImage,
      'progressPercentage': progressPercentage,
      'language': language,
      'studyMode': studyMode,
      'targetLanguage': targetLanguage,
    };
  }

  /// Crea un libro desde un Map guardado en shared_preferences
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? 'Autor Desconocido',
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      coverImage: json['coverImage'] as String?,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      language: json['language'] as String?,
      studyMode: json['studyMode'] as String?,
      targetLanguage: json['targetLanguage'] as String?,
    );
  }

  /// Calcula el porcentaje de progreso de lectura
  double get progress {
    // Si tenemos un porcentaje exacto guardado, lo usamos
    if (progressPercentage > 0) return progressPercentage;
    
    // Fallback al cálculo por capítulos
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages) * 100;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        filePath,
        fileType,
        addedDate,
        currentPage,
        totalPages,
        coverImage,
        progressPercentage,
        language,
        studyMode,
        targetLanguage,
      ];
}
