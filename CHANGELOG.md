# 📝 Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

## [1.0.0+1] - Fase 2 (Actual)

### ✨ Nuevas Características
- **Integración IA (Gemini):**
  - Análisis contextual de palabras y oraciones.
  - Detección automática de lemas y formas irregulares.
  - Generación de ejemplos de uso personalizados.
- **Modos de Estudio:**
  - Implementación de lógica para "Aprender Idioma" vs "Mejorar Vocabulario".
  - Adaptación de prompts de IA según el modo activo.
- **Base de Datos Local:**
  - Migración a `sqflite` para almacenamiento robusto de tarjetas.
  - CRUD completo para tarjetas de estudio.
- **Interfaz de Usuario:**
  - Nueva pantalla "Idiomas" con tarjetas expandibles.
  - Botones de "Traducción" ocultables para reducir ruido visual.
  - Modal de edición de tarjetas con validación y regeneración por IA.
- **Audio (TTS):**
  - Lectura en voz alta de palabras y oraciones en múltiples idiomas.
- **Exportación:**
  - Funcionalidad para exportar tarjetas a formato CSV.

### 🐛 Correcciones
- Solucionado timeout en llamadas a la API de Gemini (aumentado a 30s).
- Corregido error de renderizado en EPUBs con estilos CSS complejos.
- Mejorada la detección de selección de texto en Android.

---

## [1.0.0] - Fase 1 (MVP)

### 🎉 Lanzamiento Inicial - MVP Local

Primera versión funcional de Mi Lector Anki con todas las características básicas de un lector de libros implementadas.

---

## ✨ Nuevas Funcionalidades

### 📚 Gestión de Biblioteca
- ✅ Pantalla de biblioteca con cuadrícula de libros
- ✅ Importación de libros PDF y EPUB
- ✅ Eliminación de libros con confirmación
- ✅ Estado vacío informativo
- ✅ Botón flotante para importar
- ✅ Función de refrescar biblioteca

### 📖 Lector Universal
- ✅ Soporte completo para PDF (Syncfusion)
- ✅ Soporte completo para EPUB (Vocsy)
- ✅ Navegación fluida de páginas
- ✅ Zoom y desplazamiento en PDF
- ✅ Controles nativos en EPUB
- ✅ Contador de páginas en tiempo real

### 💾 Persistencia de Datos
- ✅ Guardado automático de progreso de lectura
- ✅ Restauración automática al reabrir
- ✅ Almacenamiento local con SharedPreferences
- ✅ Copia de archivos al directorio de la app
- ✅ Cálculo automático de porcentaje de lectura

### 🏗️ Arquitectura
- ✅ Patrón BLoC implementado
- ✅ Separación clara de responsabilidades
- ✅ Servicios modulares y reutilizables
- ✅ Manejo robusto de errores
- ✅ Estados reactivos

### 🎨 UI/UX
- ✅ Material Design 3
- ✅ Tema claro y oscuro (automático)
- ✅ Animaciones suaves
- ✅ Feedback visual (SnackBars)
- ✅ Indicadores de carga
- ✅ Diálogos de confirmación

### 📱 Multiplataforma
- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Edge)
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop

---

## 📦 Dependencias Incluidas

### Core
- `flutter_bloc: ^8.1.3` - Gestión de estado
- `equatable: ^2.0.5` - Comparación de objetos

### Almacenamiento
- `shared_preferences: ^2.2.2` - Storage local
- `path_provider: ^2.1.1` - Directorios sistema

### Lectores
- `syncfusion_flutter_pdfviewer: ^24.1.41` - PDF viewer
- `vocsy_epub_viewer: ^3.0.0` - EPUB viewer

### Utilidades
- `file_picker: ^6.1.1` - Selector de archivos
- `uuid: ^4.2.1` - Generador de IDs
- `cupertino_icons: ^1.0.8` - Iconos iOS

---

## 🏗️ Archivos Creados

### Código Fuente (11 archivos)
- `lib/main.dart` - Punto de entrada
- `lib/bloc/biblioteca_bloc.dart` - Lógica de negocio
- `lib/bloc/biblioteca_event.dart` - Eventos
- `lib/bloc/biblioteca_state.dart` - Estados
- `lib/models/book.dart` - Modelo de libro
- `lib/screens/biblioteca_screen.dart` - Pantalla principal
- `lib/screens/lector_screen.dart` - Pantalla de lectura
- `lib/services/local_storage_service.dart` - Storage
- `lib/services/file_service.dart` - Archivos
- `lib/widgets/book_card.dart` - Tarjeta de libro
- `test/widget_test.dart` - Tests

### Documentación (7 archivos)
- `README.md` - Documentación principal
- `FASE1_README.md` - Overview del proyecto
- `FASE1_COMPLETADA.md` - Detalles de implementación
- `RESUMEN_FASE1.md` - Resumen ejecutivo
- `INICIO_RAPIDO.md` - Guía visual rápida
- `COMO_EJECUTAR.md` - Instrucciones detalladas
- `ARQUITECTURA.md` - Documentación arquitectura
- `CONFIGURACION_PERMISOS.md` - Permisos por plataforma
- `CHANGELOG.md` - Este archivo

### Configuración
- `pubspec.yaml` - Dependencias actualizadas
- `android/app/src/main/AndroidManifest.xml` - Permisos Android
- `android/app/build.gradle.kts` - Configuración Android

---

## 📊 Estadísticas

- **Líneas de Código Dart**: ~1,126
- **Archivos de Código**: 11
- **Archivos de Documentación**: 9
- **Dependencias**: 8
- **Plataformas Soportadas**: 6
- **Tiempo de Desarrollo**: Fase 1

---

## 🔧 Mejoras Técnicas

### Rendimiento
- Carga eficiente de libros con caché
- Guardado asíncrono de progreso
- Optimización de memoria en lectores

### Robustez
- Manejo de errores en todos los servicios
- Validación de tipos de archivo
- Prevención de duplicados (UUID)
- Gestión de estados de error

### Código Limpio
- Separación de responsabilidades (SoC)
- Principio de inversión de dependencias (DIP)
- Código autodocumentado
- Comentarios en español

---

## 🐛 Bugs Conocidos

### Menores (No Críticos)
- EPUB abre en pantalla nativa (limitación de vocsy_epub_viewer)
- Warnings de file_picker en consola (no afectan funcionalidad)

### Próximas Mejoras
Estas funcionalidades se implementarán en fases futuras:
- Búsqueda de texto en libros
- Marcadores/Favoritos
- Notas en páginas
- Exportación de progreso

---

## 🔄 Actualizaciones desde Versión Anterior

**Primera versión** - No hay versiones anteriores.

---

## 🚀 Próximos Pasos (Fase 2)

### Planificadas para v2.0.0

#### Base de Datos SQLite
- Tabla `anki_cards` con 6 campos
- Migración desde SharedPreferences
- Queries optimizadas

#### Captura de Vocabulario
- Selección de texto en PDF
- Modal "Añadir a Anki"
- Campo de palabra
- Campo de definición (API automática)
- Campo de contexto (oración completa)
- Campo de fuente (libro + página)

#### Text-to-Speech
- Audio de palabra
- Audio de contexto
- Almacenamiento local de audios

#### API de Diccionario
- Integración con dictionaryapi.dev
- Autocompletado de definiciones
- Fallback a entrada manual

#### Pantalla de Vocabulario
- Lista de todas las palabras guardadas
- Búsqueda y filtrado
- Edición de tarjetas
- Eliminación de tarjetas

#### Exportación a Anki
- Generación de CSV
- (Avanzado) Generación de APKG
- Inclusión de archivos de audio

---

## 📝 Notas de Instalación

### Requisitos
- Flutter SDK 3.10.0+
- Dart SDK 3.10.0+
- Android Studio / VS Code
- Emulador o dispositivo físico

### Instalación Rápida
```bash
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"
flutter pub get
flutter run
```

### Permisos Requeridos

#### Android
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
- INTERNET

#### iOS
- NSPhotoLibraryUsageDescription
- NSDocumentPickerUsageDescription

---

## 🧪 Testing

### Tests Incluidos
- ✅ Test de inicialización de app
- ✅ Test de pantalla principal

### Ejecutar Tests
```bash
flutter test
```

---

## 📚 Documentación

Toda la documentación está disponible en archivos Markdown:

| Documento | Propósito |
|-----------|-----------|
| README.md | Documentación principal |
| INICIO_RAPIDO.md | Guía de inicio rápido |
| COMO_EJECUTAR.md | Instrucciones detalladas |
| ARQUITECTURA.md | Arquitectura del proyecto |
| FASE1_COMPLETADA.md | Detalles de implementación |

---

## 🙏 Agradecimientos

### Librerías de Código Abierto
- Flutter Team - Framework increíble
- Felix Angelov - flutter_bloc
- Syncfusion - Excelente visor de PDF
- Vocsy - Visor EPUB funcional

### Recursos
- Project Gutenberg - Libros de prueba
- Standard Ebooks - EPUBs de calidad
- Flutter Community - Soporte y ejemplos

---

## 📄 Licencia

Este proyecto está en desarrollo privado.

---

## 🔗 Enlaces Útiles

### Documentación
- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev)
- [Syncfusion PDF Viewer](https://help.syncfusion.com/flutter/pdf-viewer/overview)

### Recursos de Aprendizaje
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design 3](https://m3.material.io)

---

## 📞 Soporte

Para problemas o preguntas:

1. **Consulta la documentación** en los archivos MD
2. **Revisa la sección de solución de problemas** en COMO_EJECUTAR.md
3. **Ejecuta con logs detallados**: `flutter run -v`
4. **Verifica los requisitos** en README.md

---

## ✅ Checklist de Funcionalidades v1.0.0

### Implementado
- [x] Importación de libros
- [x] Biblioteca de libros
- [x] Lector de PDF
- [x] Lector de EPUB
- [x] Guardado de progreso
- [x] Eliminación de libros
- [x] Indicadores visuales
- [x] Manejo de errores
- [x] Documentación completa
- [x] Tests básicos

### Próxima Versión (v2.0.0)
- [ ] Base de datos SQLite
- [ ] Captura de vocabulario
- [ ] API de diccionario
- [ ] Text-to-Speech
- [ ] Pantalla de vocabulario
- [ ] Exportación a Anki

---

## 🎯 Objetivos Cumplidos

✅ Crear un lector MVP funcional  
✅ Implementar gestión de biblioteca  
✅ Soporte para PDF y EPUB  
✅ Guardado automático de progreso  
✅ Arquitectura escalable con BLoC  
✅ Documentación completa  
✅ Soporte multiplataforma  
✅ UI moderna con Material Design 3  

---

**Fecha de Lanzamiento**: Noviembre 2025  
**Versión**: 1.0.0  
**Estado**: Estable ✅  
**Próxima Versión**: 2.0.0 (Fase 2 - Vocabulario Local)

---

**¡Gracias por usar Mi Lector Anki! 📚✨**
