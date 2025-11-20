/// Modelo de tarjeta Anki
class AnkiCard {
  final String id;
  final String word; // Palabra o frase clave
  final String definition; // Definición (se llenará manualmente o con API)
  final String contexto; // Contexto/oración donde apareció
  final String? audioPath; // Ruta del audio TTS (opcional)
  final String bookId; // ID del libro de donde proviene
  final String fuente; // Título del libro o fuente
  final DateTime createdAt; // Fecha de creación
  final int reviewCount; // Número de veces que se ha revisado
  final DateTime? lastReviewedAt; // Última vez revisada

  AnkiCard({
    required this.id,
    required this.word,
    required this.definition,
    required this.contexto,
    this.audioPath,
    required this.bookId,
    required this.fuente,
    required this.createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  /// Crea una tarjeta desde JSON
  factory AnkiCard.fromJson(Map<String, dynamic> json) {
    return AnkiCard(
      id: json['id'] as String,
      word: json['word'] as String,
      definition: json['definition'] as String,
      contexto: json['contexto'] as String,
      audioPath: json['audioPath'] as String?,
      bookId: json['bookId'] as String,
      fuente: json['fuente'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
    );
  }

  /// Convierte la tarjeta a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'contexto': contexto,
      'audioPath': audioPath,
      'bookId': bookId,
      'fuente': fuente,
      'createdAt': createdAt.toIso8601String(),
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  /// Crea una copia con campos modificados
  AnkiCard copyWith({
    String? id,
    String? word,
    String? definition,
    String? contexto,
    String? audioPath,
    String? bookId,
    String? fuente,
    DateTime? createdAt,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return AnkiCard(
      id: id ?? this.id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      contexto: contexto ?? this.contexto,
      audioPath: audioPath ?? this.audioPath,
      bookId: bookId ?? this.bookId,
      fuente: fuente ?? this.fuente,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
