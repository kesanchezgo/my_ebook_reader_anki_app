import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/biblioteca_screen.dart';
import 'bloc/biblioteca_bloc.dart';
import 'bloc/biblioteca_event.dart';
import 'services/local_storage_service.dart';
import 'services/file_service.dart';
import 'services/settings_service.dart';
import 'config/app_theme.dart';

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
          
          return MaterialApp(
            title: 'Mi Lector',
            debugShowCheckedModeBanner: false,
            theme: appTheme.themeData,
            home: const BibliotecaScreen(),
          );
        },
      ),
    );
  }
}

