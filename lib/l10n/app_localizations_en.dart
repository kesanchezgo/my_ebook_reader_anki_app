// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get libraryTitle => 'My Library';

  @override
  String get myVocabulary => 'My Vocabulary';

  @override
  String get settings => 'Settings';

  @override
  String bookImported(String title) {
    return 'Book \"$title\" imported';
  }

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptySubtitle =>
      'Import your EPUB books to start reading\nand creating vocabulary cards.';

  @override
  String get importEpubTooltip => 'Import book (EPUB)';

  @override
  String get deleteBookTitle => 'Delete book';

  @override
  String deleteBookContent(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteReadingData => 'Also delete reading data';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get bookDeleted => 'Book deleted';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get appLanguageTitle => 'App Language';

  @override
  String get appLanguageSubtitle => 'Select the interface language.';

  @override
  String get themeTitle => 'App Theme';

  @override
  String get themeSubtitle =>
      'Select your preferred color scheme for the interface.';

  @override
  String get aiServices => 'AI SERVICES';

  @override
  String get apiCredentials => 'API Credentials';

  @override
  String get apiCredentialsSubtitle =>
      'Configure your keys to enable AI features in dictionary and explanations.';

  @override
  String get apiKeyHint => 'Paste your API Key here';

  @override
  String get smartDictionary => 'SMART DICTIONARY';

  @override
  String get definitionPriority => 'Definition Priority';

  @override
  String get definitionPrioritySubtitle =>
      'Drag to reorder which sources to consult first when looking up a word.';

  @override
  String get contextExplanation => 'CONTEXT EXPLANATION';

  @override
  String get explanationPriority => 'Explanation Priority';

  @override
  String get explanationPrioritySubtitle =>
      'Drag to reorder which AI to consult first when analyzing context.';

  @override
  String get information => 'INFORMATION';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get active => 'Active';

  @override
  String get geminiAi => 'Gemini AI (Google)';

  @override
  String get perplexityAi => 'Perplexity AI';

  @override
  String get openRouter => 'OpenRouter (Grok)';

  @override
  String get localDictionary => 'Local Dictionary (Offline)';

  @override
  String get webDictionary => 'Web (FreeDictionaryAPI)';

  @override
  String get purposeModalTitle => 'Configure Reading';

  @override
  String get purposeModalSubtitle =>
      'To provide the best experience, we need to know how you plan to read this book.';

  @override
  String get readingMode => 'Reading Mode';

  @override
  String get readOnlyMode => 'Read Only';

  @override
  String get readOnlyModeDesc => 'Enjoy the book without study tools.';

  @override
  String get nativeMode => 'Improve Vocabulary';

  @override
  String get nativeModeDesc =>
      'Look up definitions and synonyms in the same language.';

  @override
  String get studyMode => 'Learn Language';

  @override
  String get studyModeDesc =>
      'Translate words and phrases to your native language.';

  @override
  String get targetLanguage => 'Translation Language';

  @override
  String get targetLanguageDesc =>
      'Definitions and explanations will be shown in this language.';

  @override
  String get startReading => 'Start Reading';

  @override
  String get recommended => 'Recommended';

  @override
  String detectedLanguage(String language) {
    return 'Detected language: $language';
  }

  @override
  String errorLoadingBook(String error) {
    return 'Error loading book: $error';
  }

  @override
  String get errorLoadingContent => 'Could not load book content.';

  @override
  String chapterProgress(int current, int total, int percent) {
    return 'Chapter $current of $total • $percent%';
  }

  @override
  String get selectWordFirst => 'Select a word first';

  @override
  String get restore => 'Restore';

  @override
  String get textSize => 'Text Size';

  @override
  String get typography => 'Typography';

  @override
  String get alignment => 'Alignment';

  @override
  String get justified => 'Justified';

  @override
  String get left => 'Left';

  @override
  String get confirmContext => 'Confirm Context';

  @override
  String get saveCard => 'SAVE CARD';

  @override
  String get loadingChapter => 'Loading chapter...';

  @override
  String get selectingContext => 'Selecting context';

  @override
  String get selectContextInstruction =>
      'Select text and tap \"Confirm Context\"';

  @override
  String get footnoteDevelopment => 'Footnote: Navigation in development';

  @override
  String get noCardsToExport => 'No cards to export';

  @override
  String get exportingCards => 'Exporting cards...';

  @override
  String cardsExported(int count) {
    return '✓ $count cards exported';
  }

  @override
  String exportError(String error) {
    return 'Error exporting: $error';
  }

  @override
  String get deleteCard => 'Delete card';

  @override
  String deleteCardConfirmation(String word) {
    return 'Delete \"$word\"?';
  }

  @override
  String get cardDeleted => 'Card deleted';

  @override
  String get explanationError =>
      'Could not get explanation. Check your connection.';

  @override
  String get connectionError => 'Connection error';

  @override
  String get contextAnalysis => 'Context Analysis';

  @override
  String source(String source) {
    return 'Source: $source';
  }

  @override
  String get close => 'Close';

  @override
  String get originalContext => 'ORIGINAL CONTEXT';

  @override
  String get mainIdea => 'Main Idea';

  @override
  String get keyVocabulary => 'KEY VOCABULARY';

  @override
  String get usageExamples => 'Usage Examples';

  @override
  String get culturalNote => 'CULTURAL NOTE';

  @override
  String get dictionaries => 'Dictionaries';

  @override
  String get exportToCSV => 'Export to CSV';

  @override
  String get searchWords => 'Search words...';

  @override
  String get cards => 'Cards';

  @override
  String get books => 'Books';

  @override
  String get withAudio => 'With audio';

  @override
  String get noCardsSaved => 'No cards saved';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get vocabularyEmptyState =>
      'Select text in your books to create cards and review vocabulary.';

  @override
  String get playWord => 'Play word';

  @override
  String get definition => 'Definition';

  @override
  String get example => 'Example';

  @override
  String get context => 'Context';

  @override
  String get explainWithAI => 'Explain with AI';

  @override
  String get listenContext => 'Listen to context';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get definitionNotFound => 'Definition not found';

  @override
  String get searchError => 'Search error';

  @override
  String get savedToStudy => 'Saved to Study';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get createStudyCard => 'Create Study Card';

  @override
  String get wordAlreadyExists => 'This word is already in your collection.';

  @override
  String get word => 'Word';

  @override
  String get exampleOptional => 'Example (Optional)';

  @override
  String get selectFromBook => 'Select from book';

  @override
  String get dictionarySettingsTitle => 'Dictionary Settings';

  @override
  String get dictionaryLanguage => 'Dictionary Language';

  @override
  String get dictionaryLanguageQuestion =>
      'What language are the definitions in?';

  @override
  String get englishLanguage => '🇬🇧 English (EN)';

  @override
  String get spanishLanguage => '🇪🇸 Spanish (ES)';

  @override
  String get importingDictionary => 'Importing dictionary...';

  @override
  String importedWordsCount(int count) {
    return 'Imported $count words';
  }

  @override
  String get importError => 'Error importing dictionary';

  @override
  String get invalidJsonError => 'The file is not a valid JSON';

  @override
  String get invalidJsonArrayError => 'Incorrect format: JSON array expected';

  @override
  String get clearDictionary => 'Clear Dictionary';

  @override
  String get clearDictionaryConfirmation =>
      'Are you sure? All saved words will be deleted.';

  @override
  String get dictionaryCleared => 'Dictionary cleared';

  @override
  String get howItWorks => 'How it works';

  @override
  String get howItWorksDescription =>
      '1. Local dictionary is checked first (fast, offline)\n2. If word not found, searches online\n3. Words found online are saved locally';

  @override
  String get statistics => 'Statistics';

  @override
  String get spanishDictionary => '🇪🇸 Spanish Dictionary';

  @override
  String get englishDictionary => '🇬🇧 English Dictionary';

  @override
  String get totalStored => 'Total stored';

  @override
  String get diskSize => 'Disk size';

  @override
  String get actions => 'Actions';

  @override
  String get importDictionary => 'Import Dictionary';

  @override
  String get jsonFormat => 'Monolingual JSON format';

  @override
  String get dictionaryFormat => 'Dictionary Format';

  @override
  String get supportedFormats =>
      'Supported formats:\n• SpanishBFF: (\"id\", \"lemma\", \"definition\")\n• Standard: (\"word\", \"definition\", \"examples\")\n• Alternative: (\"term\", \"meaning\")\n\nNote: Monolingual dictionaries only\n(word and definition in the same language)';

  @override
  String get unknownAuthor => 'Unknown Author';

  @override
  String get appTitle => 'My Reader';

  @override
  String get langSpanish => '🇪🇸 Spanish';

  @override
  String get langEnglish => '🇺🇸 English';

  @override
  String get langFrench => '🇫🇷 French';

  @override
  String get langGerman => '🇩🇪 German';

  @override
  String get langItalian => '🇮🇹 Italian';

  @override
  String get langPortuguese => '🇧🇷 Portuguese';

  @override
  String get readerToolCapture => 'Create Card';

  @override
  String get readerToolAnalyze => 'Analyze Text';

  @override
  String get readerToolSynonyms => 'See Synonyms';

  @override
  String get promptSelectWord => 'Select the word to learn';

  @override
  String promptSelectContext(String word) {
    return 'Select sentence for: $word';
  }

  @override
  String get promptSelectText => 'Select text to analyze';

  @override
  String get actionConfirmWord => 'Confirm Word';

  @override
  String get actionConfirmContext => 'Confirm Context';

  @override
  String get actionAnalyze => 'Analyze';

  @override
  String get actionSynonyms => 'Find Synonyms';

  @override
  String get analyzingContext => 'Analyzing context with AI...';

  @override
  String creatingCardFor(String word) {
    return 'Creating card for: $word';
  }
}
