import 'package:equatable/equatable.dart';

/// Modelo que representa un libro en la biblioteca
class Book extends Equatable {
  final String id;
  final String title;
  final String filePath;
  final String fileType; // 'pdf' o 'epub'
  final DateTime addedDate;
  final int currentPage;
  final int totalPages;
  final String? coverImage; // Path a la imagen de portada (opcional)

  const Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.addedDate,
    this.currentPage = 0,
    this.totalPages = 0,
    this.coverImage,
  });

  /// Crea una copia del libro con los campos especificados modificados
  Book copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    DateTime? addedDate,
    int? currentPage,
    int? totalPages,
    String? coverImage,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      addedDate: addedDate ?? this.addedDate,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  /// Convierte el libro a un Map para guardarlo en shared_preferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileType': fileType,
      'addedDate': addedDate.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'coverImage': coverImage,
    };
  }

  /// Crea un libro desde un Map guardado en shared_preferences
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      coverImage: json['coverImage'] as String?,
    );
  }

  /// Calcula el porcentaje de progreso de lectura
  double get progress {
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages) * 100;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        filePath,
        fileType,
        addedDate,
        currentPage,
        totalPages,
        coverImage,
      ];
}
