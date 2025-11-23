import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'bloc/biblioteca_bloc.dart';
import 'bloc/biblioteca_event.dart';
import 'services/local_storage_service.dart';
import 'services/file_service.dart';
import 'services/settings_service.dart';
import 'config/app_theme.dart';

import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  final storageService = await LocalStorageService.init();
  final fileService = FileService();
  await SettingsService.instance.init();
  
  runApp(MyApp(
    storageService: storageService,
    fileService: fileService,
  ));
}

class MyApp extends StatelessWidget {
  final LocalStorageService storageService;
  final FileService fileService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.fileService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BibliotecaBloc(
        storageService: storageService,
        fileService: fileService,
      )..add(LoadBooks()),
      child: ValueListenableBuilder<String>(
        valueListenable: SettingsService.instance.themeNotifier,
        builder: (context, themeId, child) {
          final appTheme = AppTheme.getTheme(themeId);
          
          return ValueListenableBuilder<Locale?>(
            valueListenable: SettingsService.instance.localeNotifier,
            builder: (context, locale, _) {
              return MaterialApp(
                onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
                debugShowCheckedModeBanner: false,
                theme: appTheme.themeData,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HomeScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

