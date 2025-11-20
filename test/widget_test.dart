// Este es un test básico de Flutter para el lector Anki.
//
// Para ejecutar tests: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ebook_reader_anki_app/main.dart';
import 'package:my_ebook_reader_anki_app/services/local_storage_service.dart';
import 'package:my_ebook_reader_anki_app/services/file_service.dart';

void main() {
  testWidgets('App should initialize and show biblioteca screen', (WidgetTester tester) async {
    // Inicializar servicios para el test
    final storageService = await LocalStorageService.init();
    final fileService = FileService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      storageService: storageService,
      fileService: fileService,
    ));

    // Verify that biblioteca screen is shown
    expect(find.text('Mi Biblioteca'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
