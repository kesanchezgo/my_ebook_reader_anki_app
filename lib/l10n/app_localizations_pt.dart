// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get libraryTitle => 'Minha Biblioteca';

  @override
  String get myVocabulary => 'Meu Vocabulário';

  @override
  String get settings => 'Configurações';

  @override
  String bookImported(String title) {
    return 'Livro \"$title\" importado';
  }

  @override
  String get libraryEmptyTitle => 'Sua biblioteca está vazia';

  @override
  String get libraryEmptySubtitle =>
      'Importe seus livros EPUB para começar a ler\ne criar cartões de vocabulário.';

  @override
  String get importEpubTooltip => 'Importar livro (EPUB)';

  @override
  String get deleteBookTitle => 'Excluir livro';

  @override
  String deleteBookContent(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get deleteReadingData => 'Excluir também dados de leitura';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get bookDeleted => 'Livro excluído';

  @override
  String get appearance => 'APARÊNCIA';

  @override
  String get appLanguageTitle => 'Idioma do Aplicativo';

  @override
  String get appLanguageSubtitle => 'Selecione o idioma da interface.';

  @override
  String get themeTitle => 'Tema do aplicativo';

  @override
  String get themeSubtitle =>
      'Selecione o esquema de cores de sua preferência.';

  @override
  String get aiServices => 'SERVIÇOS DE IA';

  @override
  String get apiCredentials => 'Credenciais da API';

  @override
  String get apiCredentialsSubtitle =>
      'Configure suas chaves para habilitar recursos de IA no dicionário e explicações.';

  @override
  String get apiKeyHint => 'Cole sua chave de API aqui';

  @override
  String get smartDictionary => 'DICIONÁRIO INTELIGENTE';

  @override
  String get definitionPriority => 'Prioridade de Definição';

  @override
  String get definitionPrioritySubtitle =>
      'Arraste para reordenar quais fontes consultar primeiro ao buscar uma palavra.';

  @override
  String get contextExplanation => 'EXPLICAÇÃO DE CONTEXTO';

  @override
  String get explanationPriority => 'Prioridade de Explicação';

  @override
  String get explanationPrioritySubtitle =>
      'Arraste para reordenar qual IA consultar primeiro ao analisar o contexto.';

  @override
  String get information => 'INFORMAÇÕES';

  @override
  String get version => 'Versão';

  @override
  String get developer => 'Desenvolvedor';

  @override
  String get active => 'Ativo';

  @override
  String get geminiAi => 'Gemini AI (Google)';

  @override
  String get perplexityAi => 'Perplexity AI';

  @override
  String get openRouter => 'OpenRouter (Grok)';

  @override
  String get localDictionary => 'Dicionário Local (Offline)';

  @override
  String get webDictionary => 'Web (FreeDictionaryAPI)';

  @override
  String get purposeModalTitle => 'Configure sua Leitura';

  @override
  String get purposeModalSubtitle =>
      'Para oferecer a melhor experiência, precisamos saber como você planeja ler este livro.';

  @override
  String get readingMode => 'Modo de Leitura';

  @override
  String get readOnlyMode => 'Apenas Leitura';

  @override
  String get readOnlyModeDesc => 'Aproveite o livro sem ferramentas de estudo.';

  @override
  String get nativeMode => 'Melhorar Vocabulário';

  @override
  String get nativeModeDesc => 'Buscar definições e sinônimos no mesmo idioma.';

  @override
  String get studyMode => 'Aprender Idioma';

  @override
  String get studyModeDesc =>
      'Traduzir palavras e frases para seu idioma nativo.';

  @override
  String get targetLanguage => 'Idioma de Tradução';

  @override
  String get targetLanguageDesc =>
      'Definições e explicações serão mostradas neste idioma.';

  @override
  String get startReading => 'Começar Leitura';

  @override
  String get recommended => 'Recomendado';

  @override
  String detectedLanguage(String language) {
    return 'Idioma detectado: $language';
  }

  @override
  String errorLoadingBook(String error) {
    return 'Erro ao carregar livro: $error';
  }

  @override
  String get errorLoadingContent =>
      'Não foi possível carregar o conteúdo do livro.';

  @override
  String chapterProgress(int current, int total, int percent) {
    return 'Capítulo $current de $total • $percent%';
  }

  @override
  String get selectWordFirst => 'Selecione uma palavra primeiro';

  @override
  String get restore => 'Restaurar';

  @override
  String get textSize => 'Tamanho do texto';

  @override
  String get typography => 'Tipografia';

  @override
  String get alignment => 'Alinhamento';

  @override
  String get justified => 'Justificado';

  @override
  String get left => 'Esquerda';

  @override
  String get confirmContext => 'Confirmar Contexto';

  @override
  String get saveCard => 'SALVAR CARTÃO';

  @override
  String get loadingChapter => 'Carregando capítulo...';

  @override
  String get selectingContext => 'Selecionando contexto';

  @override
  String get selectContextInstruction =>
      'Selecione o texto e toque em \"Confirmar Contexto\"';

  @override
  String get footnoteDevelopment =>
      'Nota de rodapé: Navegação em desenvolvimento';

  @override
  String get noCardsToExport => 'Não há cartões para exportar';

  @override
  String get exportingCards => 'Exportando cartões...';

  @override
  String cardsExported(int count) {
    return '✓ $count cartões exportados';
  }

  @override
  String exportError(String error) {
    return 'Erro ao exportar: $error';
  }

  @override
  String get deleteCard => 'Excluir cartão';

  @override
  String deleteCardConfirmation(String word) {
    return 'Excluir \"$word\"?';
  }

  @override
  String get cardDeleted => 'Cartão excluído';

  @override
  String get analyzingContext => 'Analisando contexto com IA...';

  @override
  String get explanationError =>
      'Não foi possível obter a explicação. Verifique sua conexão.';

  @override
  String get connectionError => 'Erro de conexão';

  @override
  String get contextAnalysis => 'Análise de Contexto';

  @override
  String source(String source) {
    return 'Fonte: $source';
  }

  @override
  String get close => 'Fechar';

  @override
  String get originalContext => 'CONTEXTO ORIGINAL';

  @override
  String get mainIdea => 'Ideia Principal';

  @override
  String get keyVocabulary => 'VOCABULÁRIO CHAVE';

  @override
  String get usageExamples => 'Exemplos de Uso';

  @override
  String get culturalNote => 'NOTA CULTURAL';

  @override
  String get dictionaries => 'Dicionários';

  @override
  String get exportToCSV => 'Exportar para CSV';

  @override
  String get searchWords => 'Buscar palavras...';

  @override
  String get cards => 'Cartões';

  @override
  String get books => 'Livros';

  @override
  String get withAudio => 'Com áudio';

  @override
  String get noCardsSaved => 'Nenhum cartão salvo';

  @override
  String get noResultsFound => 'Nenhum resultado encontrado';

  @override
  String get vocabularyEmptyState =>
      'Selecione texto em seus livros para criar cartões e revisar vocabulário.';

  @override
  String get playWord => 'Reproduzir palavra';

  @override
  String get definition => 'Definição';

  @override
  String get example => 'Exemplo';

  @override
  String get context => 'Contexto';

  @override
  String get explainWithAI => 'Explicar com IA';

  @override
  String get listenContext => 'Ouvir contexto';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String daysAgo(int days) {
    return 'Há $days dias';
  }

  @override
  String get definitionNotFound => 'Definição não encontrada';

  @override
  String get searchError => 'Erro na busca';

  @override
  String get savedToStudy => 'Salvo para Estudo';

  @override
  String errorGeneric(String error) {
    return 'Erro: $error';
  }

  @override
  String get createStudyCard => 'Criar Cartão de Estudo';

  @override
  String get wordAlreadyExists => 'Esta palavra já está na sua coleção.';

  @override
  String get word => 'Palavra';

  @override
  String get exampleOptional => 'Exemplo (Opcional)';

  @override
  String get selectFromBook => 'Selecionar do livro';

  @override
  String get dictionarySettingsTitle => 'Configurações de Dicionários';

  @override
  String get dictionaryLanguage => 'Idioma do dicionário';

  @override
  String get dictionaryLanguageQuestion => 'Em que idioma estão as definições?';

  @override
  String get englishLanguage => '🇬🇧 Inglês (EN)';

  @override
  String get spanishLanguage => '🇪🇸 Espanhol (ES)';

  @override
  String get importingDictionary => 'Importando dicionário...';

  @override
  String importedWordsCount(int count) {
    return 'Importadas $count palavras';
  }

  @override
  String get importError => 'Erro ao importar dicionário';

  @override
  String get invalidJsonError => 'O arquivo não é um JSON válido';

  @override
  String get invalidJsonArrayError =>
      'Formato incorreto: esperava-se um array JSON';

  @override
  String get clearDictionary => 'Limpar Dicionário';

  @override
  String get clearDictionaryConfirmation =>
      'Tem certeza? Todas as palavras salvas serão excluídas.';

  @override
  String get dictionaryCleared => 'Dicionário limpo';

  @override
  String get howItWorks => 'Como funciona';

  @override
  String get howItWorksDescription =>
      '1. O dicionário local é consultado primeiro (rápido, offline)\n2. Se não encontrar, busca online\n3. Palavras encontradas online são salvas localmente';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get spanishDictionary => '🇪🇸 Dicionário Espanhol';

  @override
  String get englishDictionary => '🇬🇧 Dicionário Inglês';

  @override
  String get totalStored => 'Total armazenado';

  @override
  String get diskSize => 'Tamanho em disco';

  @override
  String get actions => 'Ações';

  @override
  String get importDictionary => 'Importar dicionário';

  @override
  String get jsonFormat => 'Formato JSON monolíngue';

  @override
  String get dictionaryFormat => 'Formato de dicionário';

  @override
  String get supportedFormats =>
      'Formatos suportados:\n• SpanishBFF: (\"id\", \"lemma\", \"definition\")\n• Padrão: (\"word\", \"definition\", \"examples\")\n• Alternativo: (\"term\", \"meaning\")\n\nNota: Apenas dicionários monolíngues\n(palavra e definição no mesmo idioma)';

  @override
  String get unknownAuthor => 'Autor Desconhecido';

  @override
  String get appTitle => 'Meu Leitor';

  @override
  String get langSpanish => '🇪🇸 Espanhol';

  @override
  String get langEnglish => '🇺🇸 Inglês';

  @override
  String get langFrench => '🇫🇷 Francês';

  @override
  String get langGerman => '🇩🇪 Alemão';

  @override
  String get langItalian => '🇮🇹 Italiano';

  @override
  String get langPortuguese => '🇧🇷 Português';
}
