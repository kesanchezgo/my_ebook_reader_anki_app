import 'dart:convert';

enum StudyCardType {
  enrichment, // Definición / Vocabulario
  acquisition // Traducción / Frase completa
}

/// Modelo de tarjeta de estudio (anteriormente AnkiCard)
class StudyCard {
  final String id;
  final String bookId;
  final StudyCardType type;
  final Map<String, dynamic> content; // Datos flexibles (word, definition, context, example, etc.)
  final String? audioPath; // Ruta del audio TTS (opcional)
  final String fuente; // Título del libro o fuente
  final DateTime createdAt; // Fecha de creación
  final int reviewCount; // Número de veces que se ha revisado
  final DateTime? lastReviewedAt; // Última vez revisada

  StudyCard({
    required this.id,
    required this.bookId,
    this.type = StudyCardType.enrichment,
    required this.content,
    this.audioPath,
    required this.fuente,
    required this.createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  // Getters para compatibilidad y acceso fácil
  String get word => content['word'] as String? ?? '';
  String get definition => content['definition'] as String? ?? '';
  String get context => content['context'] as String? ?? ''; 
  String get example => content['example'] as String? ?? '';

  /// Crea una tarjeta desde JSON (o Map de BD)
  factory StudyCard.fromJson(Map<String, dynamic> json) {
    // Manejo de migración: si existe 'content', úsalo. Si no, construye desde campos antiguos.
    Map<String, dynamic> contentMap;
    
    if (json['content'] != null) {
      if (json['content'] is String) {
        try {
          contentMap = jsonDecode(json['content']) as Map<String, dynamic>;
        } catch (e) {
          contentMap = {};
        }
      } else {
        contentMap = Map<String, dynamic>.from(json['content']);
      }
    } else {
      // Migración desde estructura antigua
      contentMap = {
        'word': json['word'] ?? '',
        'definition': json['definition'] ?? '',
        'context': json['contexto'] ?? '', // Mapeo de 'contexto' a 'context'
        'example': json['example'] ?? '',
      };
    }

    return StudyCard(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      type: json['type'] != null
          ? StudyCardType.values.firstWhere(
              (e) => e.toString() == json['type'],
              orElse: () => StudyCardType.enrichment,
            )
          : StudyCardType.enrichment,
      content: contentMap,
      audioPath: json['audioPath'] as String?,
      fuente: json['fuente'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
    );
  }

  /// Convierte la tarjeta a JSON para BD
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'type': type.toString(),
      'content': jsonEncode(content),
      'audioPath': audioPath,
      'fuente': fuente,
      'createdAt': createdAt.toIso8601String(),
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'word': word, // Mantenemos word para indexación y búsquedas SQL rápidas
    };
  }

  /// Crea una copia con campos modificados
  StudyCard copyWith({
    String? id,
    String? bookId,
    StudyCardType? type,
    Map<String, dynamic>? content,
    String? audioPath,
    String? fuente,
    DateTime? createdAt,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return StudyCard(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      content: content ?? Map.from(this.content),
      audioPath: audioPath ?? this.audioPath,
      fuente: fuente ?? this.fuente,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
