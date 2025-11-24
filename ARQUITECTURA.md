# 🏗️ Arquitectura del Proyecto - Mi Lector Anki

## 📐 Patrón de Arquitectura: BLoC (Business Logic Component)

El proyecto utiliza el patrón **BLoC** para separar la lógica de negocio de la presentación, proporcionando:

- ✅ Código testeable y mantenible
- ✅ Gestión de estado predecible
- ✅ Separación clara de responsabilidades
- ✅ Escalabilidad para futuras funcionalidades

## 🎯 Flujo de Datos

```
┌─────────────┐
│     UI      │ ← Muestra el estado actual
│  (Screens)  │
└──────┬──────┘
       │ Dispara eventos
       ↓
┌─────────────┐
│    BLoC     │ ← Procesa la lógica de negocio
│ (Biblioteca)│
└──────┬──────┘
       │ Llama servicios
       ↓
┌─────────────┐
│  Services   │ ← Interactúa con datos/archivos
│   (Local)   │
└──────┬──────┘
       │ Accede
       ↓
┌─────────────┐
│    Data     │ ← Almacenamiento local
│(SharedPrefs)│
└─────────────┘
```

## 📂 Estructura Detallada

```
lib/
│
├── main.dart                          # Punto de entrada
│   ├── Inicializa servicios
│   ├── Configura el BlocProvider
│   └── Define tema Material Design 3
│
├── bloc/                              # Capa de lógica de negocio
│   ├── biblioteca_bloc.dart
│   │   ├── BibliotecaBloc              # Procesa eventos
│   │   ├── Event Handlers              # Funciones _onEventName
│   │   └── Business Logic              # Valida y transforma datos
│   │
│   ├── biblioteca_event.dart
│   │   ├── LoadBooks                   # Cargar lista de libros
│   │   ├── ImportBook                  # Importar nuevo libro
│   │   ├── DeleteBook                  # Eliminar libro
│   │   ├── UpdateBook                  # Actualizar libro
│   │   └── RefreshBiblioteca           # Refrescar vista
│   │
│   └── biblioteca_state.dart
│       ├── BibliotecaInitial           # Estado inicial
│       ├── BibliotecaLoading           # Cargando datos
│       ├── BibliotecaLoaded            # Datos cargados
│       ├── BibliotecaError             # Error ocurrido
│       ├── BibliotecaImporting         # Importando libro
│       └── BibliotecaBookImported      # Libro importado
│
├── models/                            # Modelos de datos
│   ├── book.dart                      # Modelo de libro
│   └── study_card.dart                # Modelo de tarjeta de estudio (Anki)
│
├── screens/                           # Pantallas de la UI
│   ├── biblioteca_screen.dart         # Grid de libros
│   ├── lector_screen.dart             # Lector EPUB con herramientas de estudio
│   ├── idiomas_screen.dart            # Gestión de vocabulario (Adquisición)
│   ├── vocabulario_screen.dart        # Gestión de vocabulario (Enriquecimiento)
│   └── settings_screen.dart           # Configuración (API Keys, Temas)
│
├── services/                          # Servicios de negocio
│   ├── local_storage_service.dart     # SharedPreferences (Configuración)
│   ├── file_service.dart              # Gestión de archivos
│   ├── dictionary_service.dart        # Lógica de IA (Gemini)
│   ├── study_database_service.dart    # Base de datos SQLite (Tarjetas)
│   ├── tts_service.dart               # Text-to-Speech
│   └── export_service.dart            # Exportación a CSV
│
└── widgets/                           # Widgets reutilizables
    ├── book_card.dart                 # Tarjeta de libro
    ├── study_edit_modal.dart          # Modal de edición de tarjeta
    └── ai_result_modal.dart           # Modal de resultados de IA
```

## 🔄 Ciclo de Vida de un Evento

### Ejemplo: Crear una Tarjeta de Estudio

```
1. Usuario selecciona texto en LectorScreen
   ↓
2. Menú contextual: "Crear Tarjeta"
   ↓
3. DictionaryService.analyzeWord()
   ├── Llama API de Gemini
   ├── Obtiene definición, traducción y ejemplos
   └── Retorna datos estructurados
   ↓
4. StudyEditModal (UI)
   ├── Muestra datos pre-rellenados
   ├── Permite edición manual
   └── Usuario confirma "Guardar"
   ↓
5. StudyDatabaseService.insertCard()
   ├── Genera audio con TtsService
   ├── Guarda en SQLite
   └── Retorna éxito
   ↓
6. UI muestra confirmación (Toast)
```

## 🎨 Capas de la Arquitectura

### Capa de Presentación (UI)
**Responsabilidad**: Mostrar datos y capturar interacciones del usuario

- `screens/` - Pantallas completas
- `widgets/` - Componentes reutilizables
- **No contiene lógica de negocio**
- Solo dispara eventos y muestra estados

### Capa de Lógica de Negocio (BLoC)
**Responsabilidad**: Procesar eventos y transformar estados

- `bloc/` - BLoCs, Events, States
- **Coordina servicios**
- **Valida datos**
- **Transforma información**
- No conoce detalles de implementación de servicios

### Capa de Servicios
**Responsabilidad**: Interactuar con fuentes de datos

- `services/` - Servicios especializados
- **Abstrae implementación**
- **Maneja errores**
- **Proporciona API limpia**
- No depende de BLoC ni UI

### Capa de Datos
**Responsabilidad**: Modelos y estructuras de datos

- `models/` - Clases de datos
- **Serialización/Deserialización**
- **Validación de datos**
- **Inmutabilidad (copyWith)**

## 🔐 Principios de Diseño Aplicados

### 1. Separación de Responsabilidades (SoC)
Cada clase tiene una única responsabilidad:
- `Book` → Representa un libro
- `FileService` → Maneja archivos
- `LocalStorageService` → Maneja almacenamiento
- `BibliotecaBloc` → Coordina la lógica

### 2. Inversión de Dependencias (DIP)
Los BLoCs dependen de abstracciones (servicios), no de implementaciones concretas.

```dart
BibliotecaBloc({
  required LocalStorageService storageService,  // ← Inyección
  required FileService fileService,             // ← Inyección
})
```

### 3. Inmutabilidad
Los estados y eventos son inmutables usando `Equatable`:

```dart
class Book extends Equatable {
  final String id;
  final String title;
  // ... campos finales
  
  @override
  List<Object?> get props => [id, title, ...];
}
```

### 4. Single Source of Truth
El BLoC es la única fuente de verdad para el estado de la UI.

## 🧩 Patrones de Diseño Utilizados

### 1. BLoC Pattern
**Propósito**: Gestión de estado reactiva
```dart
BlocConsumer<BibliotecaBloc, BibliotecaState>(
  listener: (context, state) { /* Efectos secundarios */ },
  builder: (context, state) { /* Construir UI */ },
)
```

### 2. Repository Pattern (Preparado para Fase 3)
Los servicios actúan como repositorios de datos.

### 3. Factory Pattern
```dart
Widget _buildReader() {
  if (widget.book.fileType == 'pdf') {
    return _buildPdfReader();
  } else if (widget.book.fileType == 'epub') {
    return _buildEpubReader();
  }
  // ...
}
```

### 4. Singleton Pattern
```dart
static Future<LocalStorageService> init() async {
  final prefs = await SharedPreferences.getInstance();
  return LocalStorageService(prefs);
}
```

## 📊 Diagrama de Dependencias

```
┌─────────────────────────────────────────┐
│              main.dart                  │
│  (Inicializa e inyecta dependencias)   │
└────────────────┬────────────────────────┘
                 │
      ┌──────────┴──────────┐
      ↓                     ↓
┌──────────────┐    ┌─────────────┐
│ BibliotecaBloc│    │  Services   │
└──────┬───────┘    └─────────────┘
       │                   ↑
       │ usa               │ inyectado
       ↓                   │
┌──────────────┐           │
│   Screens    │───────────┘
└──────────────┘
       │ usa
       ↓
┌──────────────┐
│   Widgets    │
└──────────────┘
```

## 🚀 Escalabilidad para Futuras Fases

### Fase 2: Base de Datos SQLite
Agregar nueva capa:
```
lib/
├── database/
│   ├── database_helper.dart
│   └── anki_dao.dart
└── services/
    └── anki_service.dart      # Nuevo servicio
```

### Fase 3: Firebase
Agregar repositorio abstracto:
```
lib/
├── repositories/
│   ├── book_repository.dart       # Interfaz abstracta
│   ├── local_book_repository.dart # Implementación local
│   └── firebase_book_repository.dart # Implementación cloud
```

### Fase 4: Configuración de Temas
```
lib/
├── bloc/
│   ├── theme_bloc.dart
│   ├── theme_event.dart
│   └── theme_state.dart
└── themes/
    ├── app_theme.dart
    └── color_schemes.dart
```

## 🧪 Testabilidad

La arquitectura está diseñada para ser fácil de testear:

### Unit Tests (BLoC)
```dart
test('ImportBook emits BibliotecaLoaded with new book', () async {
  // Arrange
  final mockStorage = MockLocalStorageService();
  final mockFile = MockFileService();
  final bloc = BibliotecaBloc(
    storageService: mockStorage,
    fileService: mockFile,
  );
  
  // Act
  bloc.add(ImportBook());
  
  // Assert
  await expectLater(
    bloc.stream,
    emitsInOrder([
      isA<BibliotecaImporting>(),
      isA<BibliotecaLoaded>(),
    ]),
  );
});
```

### Widget Tests (UI)
```dart
testWidgets('BibliotecaScreen shows empty state', (tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => BibliotecaBloc(...),
      child: BibliotecaScreen(),
    ),
  );
  
  expect(find.text('No hay libros'), findsOneWidget);
});
```

## 💡 Mejores Prácticas Implementadas

✅ **Código autodocumentado** con nombres descriptivos  
✅ **Comentarios en español** para mejor comprensión  
✅ **Manejo de errores** en todos los servicios  
✅ **Estados de carga** para mejor UX  
✅ **Inmutabilidad** en modelos y estados  
✅ **Inyección de dependencias** para testabilidad  
✅ **Separación UI/Lógica** con BLoC pattern  

## 📚 Referencias

- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Flutter Architecture](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**Esta arquitectura está preparada para escalar desde un MVP local hasta una aplicación completa con sincronización en la nube.**
