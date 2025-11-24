import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @libraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Biblioteca'**
  String get libraryTitle;

  /// No description provided for @myVocabulary.
  ///
  /// In es, this message translates to:
  /// **'Mi Vocabulario'**
  String get myVocabulary;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @bookImported.
  ///
  /// In es, this message translates to:
  /// **'Libro \"{title}\" importado'**
  String bookImported(String title);

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Importa tus libros EPUB para empezar a leer\ny crear tarjetas de vocabulario.'**
  String get libraryEmptySubtitle;

  /// No description provided for @importEpubTooltip.
  ///
  /// In es, this message translates to:
  /// **'Importar libro (EPUB)'**
  String get importEpubTooltip;

  /// No description provided for @deleteBookTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar libro'**
  String get deleteBookTitle;

  /// No description provided for @deleteBookContent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar \"{title}\"?'**
  String deleteBookContent(String title);

  /// No description provided for @deleteReadingData.
  ///
  /// In es, this message translates to:
  /// **'Eliminar también datos de lectura'**
  String get deleteReadingData;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @bookDeleted.
  ///
  /// In es, this message translates to:
  /// **'Libro eliminado'**
  String get bookDeleted;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get appearance;

  /// No description provided for @appLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la Aplicación'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma de la interfaz.'**
  String get appLanguageSubtitle;

  /// No description provided for @themeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema de la aplicación'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el esquema de colores que prefieras para la interfaz.'**
  String get themeSubtitle;

  /// No description provided for @aiServices.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS DE IA'**
  String get aiServices;

  /// No description provided for @apiCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales de API'**
  String get apiCredentials;

  /// No description provided for @apiCredentialsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tus claves para habilitar las funciones de IA en el diccionario y explicaciones.'**
  String get apiCredentialsSubtitle;

  /// No description provided for @apiKeyHint.
  ///
  /// In es, this message translates to:
  /// **'Pega tu API Key aquí'**
  String get apiKeyHint;

  /// No description provided for @smartDictionary.
  ///
  /// In es, this message translates to:
  /// **'DICCIONARIO INTELIGENTE'**
  String get smartDictionary;

  /// No description provided for @definitionPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad de Definición'**
  String get definitionPriority;

  /// No description provided for @definitionPrioritySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar qué fuentes consultar primero al buscar una palabra.'**
  String get definitionPrioritySubtitle;

  /// No description provided for @contextExplanation.
  ///
  /// In es, this message translates to:
  /// **'EXPLICACIÓN DE CONTEXTO'**
  String get contextExplanation;

  /// No description provided for @explanationPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad de Explicación'**
  String get explanationPriority;

  /// No description provided for @explanationPrioritySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar qué IA consultar primero al analizar el contexto.'**
  String get explanationPrioritySubtitle;

  /// No description provided for @information.
  ///
  /// In es, this message translates to:
  /// **'INFORMACIÓN'**
  String get information;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In es, this message translates to:
  /// **'Desarrollador'**
  String get developer;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get active;

  /// No description provided for @geminiAi.
  ///
  /// In es, this message translates to:
  /// **'Gemini AI (Google)'**
  String get geminiAi;

  /// No description provided for @perplexityAi.
  ///
  /// In es, this message translates to:
  /// **'Perplexity AI'**
  String get perplexityAi;

  /// No description provided for @openRouter.
  ///
  /// In es, this message translates to:
  /// **'OpenRouter (Grok)'**
  String get openRouter;

  /// No description provided for @localDictionary.
  ///
  /// In es, this message translates to:
  /// **'Diccionario Local (Offline)'**
  String get localDictionary;

  /// No description provided for @webDictionary.
  ///
  /// In es, this message translates to:
  /// **'Web (FreeDictionaryAPI)'**
  String get webDictionary;

  /// No description provided for @purposeModalTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu Lectura'**
  String get purposeModalTitle;

  /// No description provided for @purposeModalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para ofrecerte la mejor experiencia, necesitamos saber cómo planeas leer este libro.'**
  String get purposeModalSubtitle;

  /// No description provided for @readingMode.
  ///
  /// In es, this message translates to:
  /// **'Modo de Lectura'**
  String get readingMode;

  /// No description provided for @readOnlyMode.
  ///
  /// In es, this message translates to:
  /// **'Solo Lectura'**
  String get readOnlyMode;

  /// No description provided for @readOnlyModeDesc.
  ///
  /// In es, this message translates to:
  /// **'Disfrutar del libro sin herramientas de estudio.'**
  String get readOnlyModeDesc;

  /// No description provided for @nativeMode.
  ///
  /// In es, this message translates to:
  /// **'Mejorar Vocabulario'**
  String get nativeMode;

  /// No description provided for @nativeModeDesc.
  ///
  /// In es, this message translates to:
  /// **'Buscar definiciones y sinónimos en el mismo idioma.'**
  String get nativeModeDesc;

  /// No description provided for @studyMode.
  ///
  /// In es, this message translates to:
  /// **'Aprender Idioma'**
  String get studyMode;

  /// No description provided for @studyModeDesc.
  ///
  /// In es, this message translates to:
  /// **'Traducir palabras y frases a tu idioma nativo.'**
  String get studyModeDesc;

  /// No description provided for @targetLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma de Traducción'**
  String get targetLanguage;

  /// No description provided for @targetLanguageDesc.
  ///
  /// In es, this message translates to:
  /// **'Las definiciones y explicaciones se mostrarán en este idioma.'**
  String get targetLanguageDesc;

  /// No description provided for @startReading.
  ///
  /// In es, this message translates to:
  /// **'Comenzar Lectura'**
  String get startReading;

  /// No description provided for @recommended.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get recommended;

  /// No description provided for @detectedLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma detectado: {language}'**
  String detectedLanguage(String language);

  /// No description provided for @errorLoadingBook.
  ///
  /// In es, this message translates to:
  /// **'Error cargando libro: {error}'**
  String errorLoadingBook(String error);

  /// No description provided for @errorLoadingContent.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el contenido del libro.'**
  String get errorLoadingContent;

  /// No description provided for @chapterProgress.
  ///
  /// In es, this message translates to:
  /// **'Capítulo {current} de {total} • {percent}%'**
  String chapterProgress(int current, int total, int percent);

  /// No description provided for @selectWordFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una palabra primero'**
  String get selectWordFirst;

  /// No description provided for @restore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @textSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de texto'**
  String get textSize;

  /// No description provided for @typography.
  ///
  /// In es, this message translates to:
  /// **'Tipografía'**
  String get typography;

  /// No description provided for @alignment.
  ///
  /// In es, this message translates to:
  /// **'Alineación'**
  String get alignment;

  /// No description provided for @justified.
  ///
  /// In es, this message translates to:
  /// **'Justificado'**
  String get justified;

  /// No description provided for @left.
  ///
  /// In es, this message translates to:
  /// **'Izquierda'**
  String get left;

  /// No description provided for @confirmContext.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Oración'**
  String get confirmContext;

  /// No description provided for @saveCard.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR TARJETA'**
  String get saveCard;

  /// No description provided for @loadingChapter.
  ///
  /// In es, this message translates to:
  /// **'Cargando capítulo...'**
  String get loadingChapter;

  /// No description provided for @selectingContext.
  ///
  /// In es, this message translates to:
  /// **'Seleccionando contexto'**
  String get selectingContext;

  /// No description provided for @selectContextInstruction.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el texto y pulsa \"Confirmar Oración\"'**
  String get selectContextInstruction;

  /// No description provided for @footnoteDevelopment.
  ///
  /// In es, this message translates to:
  /// **'Nota al pie: Navegación en desarrollo'**
  String get footnoteDevelopment;

  /// No description provided for @noCardsToExport.
  ///
  /// In es, this message translates to:
  /// **'No hay tarjetas para exportar'**
  String get noCardsToExport;

  /// No description provided for @exportingCards.
  ///
  /// In es, this message translates to:
  /// **'Exportando tarjetas...'**
  String get exportingCards;

  /// No description provided for @cardsExported.
  ///
  /// In es, this message translates to:
  /// **'✓ {count} tarjetas exportadas'**
  String cardsExported(int count);

  /// No description provided for @exportError.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar: {error}'**
  String exportError(String error);

  /// No description provided for @deleteCard.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tarjeta'**
  String get deleteCard;

  /// No description provided for @deleteCardConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{word}\"?'**
  String deleteCardConfirmation(String word);

  /// No description provided for @cardDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta eliminada'**
  String get cardDeleted;

  /// No description provided for @explanationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la explicación. Verifica tu conexión.'**
  String get explanationError;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get connectionError;

  /// No description provided for @contextAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de Contexto'**
  String get contextAnalysis;

  /// No description provided for @source.
  ///
  /// In es, this message translates to:
  /// **'Fuente: {source}'**
  String source(String source);

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @originalContext.
  ///
  /// In es, this message translates to:
  /// **'Oración del libro'**
  String get originalContext;

  /// No description provided for @contextTranslation.
  ///
  /// In es, this message translates to:
  /// **'Traducción de la Oración'**
  String get contextTranslation;

  /// No description provided for @mainIdea.
  ///
  /// In es, this message translates to:
  /// **'Idea Principal'**
  String get mainIdea;

  /// No description provided for @keyVocabulary.
  ///
  /// In es, this message translates to:
  /// **'VOCABULARIO CLAVE'**
  String get keyVocabulary;

  /// No description provided for @usageExamples.
  ///
  /// In es, this message translates to:
  /// **'Ejemplos de Uso'**
  String get usageExamples;

  /// No description provided for @culturalNote.
  ///
  /// In es, this message translates to:
  /// **'NOTA CULTURAL'**
  String get culturalNote;

  /// No description provided for @dictionaries.
  ///
  /// In es, this message translates to:
  /// **'Diccionarios'**
  String get dictionaries;

  /// No description provided for @exportToCSV.
  ///
  /// In es, this message translates to:
  /// **'Exportar a CSV'**
  String get exportToCSV;

  /// No description provided for @searchWords.
  ///
  /// In es, this message translates to:
  /// **'Buscar palabras...'**
  String get searchWords;

  /// No description provided for @cards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas'**
  String get cards;

  /// No description provided for @books.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get books;

  /// No description provided for @withAudio.
  ///
  /// In es, this message translates to:
  /// **'Con audio'**
  String get withAudio;

  /// No description provided for @noCardsSaved.
  ///
  /// In es, this message translates to:
  /// **'No hay tarjetas guardadas'**
  String get noCardsSaved;

  /// No description provided for @noResultsFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get noResultsFound;

  /// No description provided for @vocabularyEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Selecciona texto en tus libros para crear tarjetas y repasar vocabulario.'**
  String get vocabularyEmptyState;

  /// No description provided for @playWord.
  ///
  /// In es, this message translates to:
  /// **'Reproducir palabra'**
  String get playWord;

  /// No description provided for @definition.
  ///
  /// In es, this message translates to:
  /// **'Definición'**
  String get definition;

  /// No description provided for @example.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo'**
  String get example;

  /// No description provided for @context.
  ///
  /// In es, this message translates to:
  /// **'Contexto'**
  String get context;

  /// No description provided for @explainWithAI.
  ///
  /// In es, this message translates to:
  /// **'Explicar con IA'**
  String get explainWithAI;

  /// No description provided for @listenContext.
  ///
  /// In es, this message translates to:
  /// **'Escuchar contexto'**
  String get listenContext;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {days} días'**
  String daysAgo(int days);

  /// No description provided for @definitionNotFound.
  ///
  /// In es, this message translates to:
  /// **'Definición no encontrada'**
  String get definitionNotFound;

  /// No description provided for @searchError.
  ///
  /// In es, this message translates to:
  /// **'Error en la búsqueda'**
  String get searchError;

  /// No description provided for @savedToStudy.
  ///
  /// In es, this message translates to:
  /// **'Guardado en Estudio'**
  String get savedToStudy;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @createStudyCard.
  ///
  /// In es, this message translates to:
  /// **'Nueva Tarjeta'**
  String get createStudyCard;

  /// No description provided for @wordAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Esta palabra ya está en tu colección.'**
  String get wordAlreadyExists;

  /// No description provided for @word.
  ///
  /// In es, this message translates to:
  /// **'Palabra'**
  String get word;

  /// No description provided for @exampleOptional.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo (Opcional)'**
  String get exampleOptional;

  /// No description provided for @selectFromBook.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar del libro'**
  String get selectFromBook;

  /// No description provided for @dictionarySettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Diccionarios'**
  String get dictionarySettingsTitle;

  /// No description provided for @dictionaryLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma del diccionario'**
  String get dictionaryLanguage;

  /// No description provided for @dictionaryLanguageQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿En qué idioma están las definiciones?'**
  String get dictionaryLanguageQuestion;

  /// No description provided for @englishLanguage.
  ///
  /// In es, this message translates to:
  /// **'🇬🇧 Inglés (EN)'**
  String get englishLanguage;

  /// No description provided for @spanishLanguage.
  ///
  /// In es, this message translates to:
  /// **'🇪🇸 Español (ES)'**
  String get spanishLanguage;

  /// No description provided for @importingDictionary.
  ///
  /// In es, this message translates to:
  /// **'Importando diccionario...'**
  String get importingDictionary;

  /// No description provided for @importedWordsCount.
  ///
  /// In es, this message translates to:
  /// **'Importadas {count} palabras'**
  String importedWordsCount(int count);

  /// No description provided for @importError.
  ///
  /// In es, this message translates to:
  /// **'Error al importar diccionario'**
  String get importError;

  /// No description provided for @invalidJsonError.
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un JSON válido'**
  String get invalidJsonError;

  /// No description provided for @invalidJsonArrayError.
  ///
  /// In es, this message translates to:
  /// **'Formato incorrecto: se esperaba un array JSON'**
  String get invalidJsonArrayError;

  /// No description provided for @clearDictionary.
  ///
  /// In es, this message translates to:
  /// **'Limpiar diccionario'**
  String get clearDictionary;

  /// No description provided for @clearDictionaryConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? Se eliminarán todas las palabras guardadas.'**
  String get clearDictionaryConfirmation;

  /// No description provided for @dictionaryCleared.
  ///
  /// In es, this message translates to:
  /// **'Diccionario limpiado'**
  String get dictionaryCleared;

  /// No description provided for @howItWorks.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona'**
  String get howItWorks;

  /// No description provided for @howItWorksDescription.
  ///
  /// In es, this message translates to:
  /// **'1. El diccionario local se consulta primero (rápido, offline)\n2. Si no encuentra la palabra, busca online\n3. Las palabras encontradas online se guardan localmente'**
  String get howItWorksDescription;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @spanishDictionary.
  ///
  /// In es, this message translates to:
  /// **'🇪🇸 Diccionario Español'**
  String get spanishDictionary;

  /// No description provided for @englishDictionary.
  ///
  /// In es, this message translates to:
  /// **'🇬🇧 Diccionario English'**
  String get englishDictionary;

  /// No description provided for @totalStored.
  ///
  /// In es, this message translates to:
  /// **'Total almacenado'**
  String get totalStored;

  /// No description provided for @diskSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño en disco'**
  String get diskSize;

  /// No description provided for @actions.
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get actions;

  /// No description provided for @importDictionary.
  ///
  /// In es, this message translates to:
  /// **'Importar diccionario'**
  String get importDictionary;

  /// No description provided for @jsonFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato JSON monolingüe'**
  String get jsonFormat;

  /// No description provided for @dictionaryFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato de diccionario'**
  String get dictionaryFormat;

  /// No description provided for @supportedFormats.
  ///
  /// In es, this message translates to:
  /// **'Formatos soportados:\n• SpanishBFF: (\"id\", \"lemma\", \"definition\")\n• Estándar: (\"word\", \"definition\", \"examples\")\n• Alternativo: (\"term\", \"meaning\")\n\nNota: Diccionarios monolingües solamente\n(palabra y definición en el mismo idioma)'**
  String get supportedFormats;

  /// No description provided for @unknownAuthor.
  ///
  /// In es, this message translates to:
  /// **'Autor Desconocido'**
  String get unknownAuthor;

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Lector'**
  String get appTitle;

  /// No description provided for @langSpanish.
  ///
  /// In es, this message translates to:
  /// **'🇪🇸 Español'**
  String get langSpanish;

  /// No description provided for @langEnglish.
  ///
  /// In es, this message translates to:
  /// **'🇺🇸 Inglés'**
  String get langEnglish;

  /// No description provided for @langFrench.
  ///
  /// In es, this message translates to:
  /// **'🇫🇷 Francés'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In es, this message translates to:
  /// **'🇩🇪 Alemán'**
  String get langGerman;

  /// No description provided for @langItalian.
  ///
  /// In es, this message translates to:
  /// **'🇮🇹 Italiano'**
  String get langItalian;

  /// No description provided for @langPortuguese.
  ///
  /// In es, this message translates to:
  /// **'🇧🇷 Portugués'**
  String get langPortuguese;

  /// No description provided for @readerToolCapture.
  ///
  /// In es, this message translates to:
  /// **'Crear Tarjeta'**
  String get readerToolCapture;

  /// No description provided for @readerToolAnalyze.
  ///
  /// In es, this message translates to:
  /// **'Analizar Texto'**
  String get readerToolAnalyze;

  /// No description provided for @readerToolSynonyms.
  ///
  /// In es, this message translates to:
  /// **'Ver Sinónimos'**
  String get readerToolSynonyms;

  /// No description provided for @promptSelectWord.
  ///
  /// In es, this message translates to:
  /// **'Elige la palabra a estudiar'**
  String get promptSelectWord;

  /// No description provided for @promptSelectContext.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la oración para: {word}'**
  String promptSelectContext(String word);

  /// No description provided for @promptSelectContextVocab.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el contexto para: {word}'**
  String promptSelectContextVocab(String word);

  /// No description provided for @actionConfirmContextVocab.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contexto'**
  String get actionConfirmContextVocab;

  /// No description provided for @promptSelectText.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el texto a analizar'**
  String get promptSelectText;

  /// No description provided for @actionConfirmWord.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Palabra'**
  String get actionConfirmWord;

  /// No description provided for @actionConfirmContext.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Oración'**
  String get actionConfirmContext;

  /// No description provided for @actionAnalyze.
  ///
  /// In es, this message translates to:
  /// **'Analizar'**
  String get actionAnalyze;

  /// No description provided for @actionSynonyms.
  ///
  /// In es, this message translates to:
  /// **'Buscar Sinónimos'**
  String get actionSynonyms;

  /// No description provided for @analyzingContext.
  ///
  /// In es, this message translates to:
  /// **'Analizando contexto con IA...'**
  String get analyzingContext;

  /// No description provided for @creatingCardFor.
  ///
  /// In es, this message translates to:
  /// **'Creando tarjeta para: {word}'**
  String creatingCardFor(String word);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
