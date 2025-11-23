// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get libraryTitle => 'Mi Biblioteca';

  @override
  String get myVocabulary => 'Mi Vocabulario';

  @override
  String get settings => 'Configuración';

  @override
  String bookImported(String title) {
    return 'Libro \"$title\" importado';
  }

  @override
  String get libraryEmptyTitle => 'Tu biblioteca está vacía';

  @override
  String get libraryEmptySubtitle =>
      'Importa tus libros EPUB para empezar a leer\ny crear tarjetas de vocabulario.';

  @override
  String get importEpubTooltip => 'Importar libro (EPUB)';

  @override
  String get deleteBookTitle => 'Eliminar libro';

  @override
  String deleteBookContent(String title) {
    return '¿Estás seguro de que quieres eliminar \"$title\"?';
  }

  @override
  String get deleteReadingData => 'Eliminar también datos de lectura';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get bookDeleted => 'Libro eliminado';

  @override
  String get appearance => 'APARIENCIA';

  @override
  String get appLanguageTitle => 'Idioma de la Aplicación';

  @override
  String get appLanguageSubtitle => 'Selecciona el idioma de la interfaz.';

  @override
  String get themeTitle => 'Tema de la aplicación';

  @override
  String get themeSubtitle =>
      'Selecciona el esquema de colores que prefieras para la interfaz.';

  @override
  String get aiServices => 'SERVICIOS DE IA';

  @override
  String get apiCredentials => 'Credenciales de API';

  @override
  String get apiCredentialsSubtitle =>
      'Configura tus claves para habilitar las funciones de IA en el diccionario y explicaciones.';

  @override
  String get apiKeyHint => 'Pega tu API Key aquí';

  @override
  String get smartDictionary => 'DICCIONARIO INTELIGENTE';

  @override
  String get definitionPriority => 'Prioridad de Definición';

  @override
  String get definitionPrioritySubtitle =>
      'Arrastra para reordenar qué fuentes consultar primero al buscar una palabra.';

  @override
  String get contextExplanation => 'EXPLICACIÓN DE CONTEXTO';

  @override
  String get explanationPriority => 'Prioridad de Explicación';

  @override
  String get explanationPrioritySubtitle =>
      'Arrastra para reordenar qué IA consultar primero al analizar el contexto.';

  @override
  String get information => 'INFORMACIÓN';

  @override
  String get version => 'Versión';

  @override
  String get developer => 'Desarrollador';

  @override
  String get active => 'Activo';

  @override
  String get geminiAi => 'Gemini AI (Google)';

  @override
  String get perplexityAi => 'Perplexity AI';

  @override
  String get openRouter => 'OpenRouter (Grok)';

  @override
  String get localDictionary => 'Diccionario Local (Offline)';

  @override
  String get webDictionary => 'Web (FreeDictionaryAPI)';

  @override
  String get purposeModalTitle => 'Configura tu Lectura';

  @override
  String get purposeModalSubtitle =>
      'Para ofrecerte la mejor experiencia, necesitamos saber cómo planeas leer este libro.';

  @override
  String get readingMode => 'Modo de Lectura';

  @override
  String get readOnlyMode => 'Solo Lectura';

  @override
  String get readOnlyModeDesc =>
      'Disfrutar del libro sin herramientas de estudio.';

  @override
  String get nativeMode => 'Mejorar Vocabulario';

  @override
  String get nativeModeDesc =>
      'Buscar definiciones y sinónimos en el mismo idioma.';

  @override
  String get studyMode => 'Aprender Idioma';

  @override
  String get studyModeDesc => 'Traducir palabras y frases a tu idioma nativo.';

  @override
  String get targetLanguage => 'Idioma de Traducción';

  @override
  String get targetLanguageDesc =>
      'Las definiciones y explicaciones se mostrarán en este idioma.';

  @override
  String get startReading => 'Comenzar Lectura';

  @override
  String get recommended => 'Recomendado';

  @override
  String detectedLanguage(String language) {
    return 'Idioma detectado: $language';
  }

  @override
  String errorLoadingBook(String error) {
    return 'Error cargando libro: $error';
  }

  @override
  String get errorLoadingContent => 'No se pudo cargar el contenido del libro.';

  @override
  String chapterProgress(int current, int total, int percent) {
    return 'Capítulo $current de $total • $percent%';
  }

  @override
  String get selectWordFirst => 'Selecciona una palabra primero';

  @override
  String get restore => 'Restaurar';

  @override
  String get textSize => 'Tamaño de texto';

  @override
  String get typography => 'Tipografía';

  @override
  String get alignment => 'Alineación';

  @override
  String get justified => 'Justificado';

  @override
  String get left => 'Izquierda';

  @override
  String get confirmContext => 'Confirmar Contexto';

  @override
  String get saveCard => 'GUARDAR TARJETA';

  @override
  String get loadingChapter => 'Cargando capítulo...';

  @override
  String get selectingContext => 'Seleccionando contexto';

  @override
  String get selectContextInstruction =>
      'Selecciona el texto y pulsa \"Confirmar Contexto\"';

  @override
  String get footnoteDevelopment => 'Nota al pie: Navegación en desarrollo';

  @override
  String get noCardsToExport => 'No hay tarjetas para exportar';

  @override
  String get exportingCards => 'Exportando tarjetas...';

  @override
  String cardsExported(int count) {
    return '✓ $count tarjetas exportadas';
  }

  @override
  String exportError(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get deleteCard => 'Eliminar tarjeta';

  @override
  String deleteCardConfirmation(String word) {
    return '¿Eliminar \"$word\"?';
  }

  @override
  String get cardDeleted => 'Tarjeta eliminada';

  @override
  String get analyzingContext => 'Analizando contexto con IA...';

  @override
  String get explanationError =>
      'No se pudo obtener la explicación. Verifica tu conexión.';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get contextAnalysis => 'Análisis de Contexto';

  @override
  String source(String source) {
    return 'Fuente: $source';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get originalContext => 'CONTEXTO ORIGINAL';

  @override
  String get mainIdea => 'Idea Principal';

  @override
  String get keyVocabulary => 'VOCABULARIO CLAVE';

  @override
  String get usageExamples => 'Ejemplos de Uso';

  @override
  String get culturalNote => 'NOTA CULTURAL';

  @override
  String get dictionaries => 'Diccionarios';

  @override
  String get exportToCSV => 'Exportar a CSV';

  @override
  String get searchWords => 'Buscar palabras...';

  @override
  String get cards => 'Tarjetas';

  @override
  String get books => 'Libros';

  @override
  String get withAudio => 'Con audio';

  @override
  String get noCardsSaved => 'No hay tarjetas guardadas';

  @override
  String get noResultsFound => 'No se encontraron resultados';

  @override
  String get vocabularyEmptyState =>
      'Selecciona texto en tus libros para crear tarjetas y repasar vocabulario.';

  @override
  String get playWord => 'Reproducir palabra';

  @override
  String get definition => 'Definición';

  @override
  String get example => 'Ejemplo';

  @override
  String get context => 'Contexto';

  @override
  String get explainWithAI => 'Explicar con IA';

  @override
  String get listenContext => 'Escuchar contexto';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int days) {
    return 'Hace $days días';
  }

  @override
  String get definitionNotFound => 'Definición no encontrada';

  @override
  String get searchError => 'Error en la búsqueda';

  @override
  String get savedToStudy => 'Guardado en Estudio';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get createStudyCard => 'Crear Tarjeta de Estudio';

  @override
  String get wordAlreadyExists => 'Esta palabra ya está en tu colección.';

  @override
  String get word => 'Palabra';

  @override
  String get exampleOptional => 'Ejemplo (Opcional)';

  @override
  String get selectFromBook => 'Seleccionar del libro';

  @override
  String get dictionarySettingsTitle => 'Configuración de Diccionarios';

  @override
  String get dictionaryLanguage => 'Idioma del diccionario';

  @override
  String get dictionaryLanguageQuestion =>
      '¿En qué idioma están las definiciones?';

  @override
  String get englishLanguage => '🇬🇧 Inglés (EN)';

  @override
  String get spanishLanguage => '🇪🇸 Español (ES)';

  @override
  String get importingDictionary => 'Importando diccionario...';

  @override
  String importedWordsCount(int count) {
    return 'Importadas $count palabras';
  }

  @override
  String get importError => 'Error al importar diccionario';

  @override
  String get invalidJsonError => 'El archivo no es un JSON válido';

  @override
  String get invalidJsonArrayError =>
      'Formato incorrecto: se esperaba un array JSON';

  @override
  String get clearDictionary => 'Limpiar diccionario';

  @override
  String get clearDictionaryConfirmation =>
      '¿Estás seguro? Se eliminarán todas las palabras guardadas.';

  @override
  String get dictionaryCleared => 'Diccionario limpiado';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get howItWorksDescription =>
      '1. El diccionario local se consulta primero (rápido, offline)\n2. Si no encuentra la palabra, busca online\n3. Las palabras encontradas online se guardan localmente';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get spanishDictionary => '🇪🇸 Diccionario Español';

  @override
  String get englishDictionary => '🇬🇧 Diccionario English';

  @override
  String get totalStored => 'Total almacenado';

  @override
  String get diskSize => 'Tamaño en disco';

  @override
  String get actions => 'Acciones';

  @override
  String get importDictionary => 'Importar diccionario';

  @override
  String get jsonFormat => 'Formato JSON monolingüe';

  @override
  String get dictionaryFormat => 'Formato de diccionario';

  @override
  String get supportedFormats =>
      'Formatos soportados:\n• SpanishBFF: (\"id\", \"lemma\", \"definition\")\n• Estándar: (\"word\", \"definition\", \"examples\")\n• Alternativo: (\"term\", \"meaning\")\n\nNota: Diccionarios monolingües solamente\n(palabra y definición en el mismo idioma)';

  @override
  String get unknownAuthor => 'Autor Desconocido';

  @override
  String get appTitle => 'Mi Lector';

  @override
  String get langSpanish => '🇪🇸 Español';

  @override
  String get langEnglish => '🇺🇸 Inglés';

  @override
  String get langFrench => '🇫🇷 Francés';

  @override
  String get langGerman => '🇩🇪 Alemán';

  @override
  String get langItalian => '🇮🇹 Italiano';

  @override
  String get langPortuguese => '🇧🇷 Portugués';

  @override
  String get readerToolCapture => 'Capturar Ficha';

  @override
  String get readerToolAnalyze => 'Analizar Texto';

  @override
  String get readerToolSynonyms => 'Ver Sinónimos';

  @override
  String get promptSelectWord => 'Selecciona la palabra a aprender';

  @override
  String get promptSelectContext => 'Ahora selecciona el contexto';

  @override
  String get promptSelectText => 'Selecciona el texto a analizar';

  @override
  String get actionConfirmWord => 'Confirmar Palabra';

  @override
  String get actionConfirmContext => 'Confirmar Contexto';

  @override
  String get actionAnalyze => 'Analizar';

  @override
  String get actionSynonyms => 'Buscar Sinónimos';
}
