# Mi Lector Anki - Aplicación de Lectura con Integración Anki

Una aplicación multiplataforma de lectura de libros (PDF/EPUB) con integración avanzada para capturar vocabulario y exportarlo a Anki, diseñada para reducir la fatiga visual.

## 📚 Estado del Proyecto

### ✅ Fase 1 Completada: El Lector MVP Local

La Fase 1 está completamente implementada con las siguientes características:

#### Funcionalidades Implementadas:

1. **Importación de Libros**
   - Soporte para archivos PDF y EPUB
   - Selector de archivos nativo usando `file_picker`
   - Copia automática de libros al directorio de la aplicación
   - Almacenamiento persistente usando `shared_preferences`

2. **Biblioteca de Libros**
   - Vista en cuadrícula de todos los libros importados
   - Tarjetas con información visual (tipo de archivo, título)
   - Indicador de progreso de lectura
   - Función de eliminar libros

3. **Lector de Libros**
   - Visor de PDF con navegación y zoom (Syncfusion)
   - Visor de EPUB con controles nativos (Vocsy)
   - Guardado automático de progreso de lectura
   - Restauración automática de la última página leída

4. **Gestión de Estado**
   - Implementación con BLoC pattern
   - Manejo de estados (carga, éxito, error)
   - Eventos reactivos para todas las acciones

## 🏗️ Estructura del Proyecto

```
lib/
├── bloc/                          # Gestión de estado con BLoC
│   ├── biblioteca_bloc.dart       # Lógica de negocio de la biblioteca
│   ├── biblioteca_event.dart      # Eventos de la biblioteca
│   └── biblioteca_state.dart      # Estados de la biblioteca
│
├── models/                        # Modelos de datos
│   └── book.dart                  # Modelo de libro con serialización
│
├── screens/                       # Pantallas de la aplicación
│   ├── biblioteca_screen.dart     # Pantalla principal con la biblioteca
│   └── lector_screen.dart         # Pantalla del lector (PDF/EPUB)
│
├── services/                      # Servicios y lógica de negocio
│   ├── local_storage_service.dart # Gestión de almacenamiento local
│   └── file_service.dart          # Gestión de archivos
│
├── widgets/                       # Widgets reutilizables
│   └── book_card.dart             # Tarjeta de libro para la biblioteca
│
└── main.dart                      # Punto de entrada de la aplicación
```

## 📦 Dependencias Actuales

```yaml
dependencies:
  flutter_bloc: ^8.1.3          # Gestión de estado
  equatable: ^2.0.5             # Comparación de objetos
  shared_preferences: ^2.2.2    # Almacenamiento local clave-valor
  path_provider: ^2.1.1         # Acceso a directorios del sistema
  file_picker: ^6.1.1           # Selector de archivos
  syncfusion_flutter_pdfviewer: ^24.1.41  # Visor de PDF
  vocsy_epub_viewer: ^3.0.0     # Visor de EPUB
  uuid: ^4.2.1                  # Generación de IDs únicos
```

## 🚀 Cómo Ejecutar

1. Asegúrate de tener Flutter instalado (3.10.0 o superior)
2. Instala las dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 📱 Funcionalidades de la Fase 1

### BibliotecaScreen
- **Vista principal** con cuadrícula de libros
- **Botón flotante (+)** para importar nuevos libros
- **Tarjetas de libro** con:
  - Indicador visual del tipo (PDF/EPUB)
  - Título del libro
  - Barra de progreso de lectura
  - Botón de eliminar
- **Estado vacío** con mensaje informativo

### LectorScreen
- **Detección automática** del formato de archivo
- **Visor PDF** (Syncfusion):
  - Navegación de páginas
  - Zoom y desplazamiento
  - Contador de páginas
  - Selección de texto (preparado para Fase 2)
- **Visor EPUB** (Vocsy):
  - Navegación por capítulos
  - Personalización de fuente (nativo)
  - Modo nocturno (nativo)
- **Guardado automático** del progreso al salir
- **Restauración** de la última página al abrir

## 🔜 Próximas Fases

### Fase 2: Integración de Vocabulario Local (Offline)
- Base de datos SQLite con 6 campos para tarjetas Anki
- Captura de palabras con selección de texto
- API de diccionario para definiciones automáticas
- Text-to-Speech para audio de palabras y contexto
- Pantalla de vocabulario
- Exportación a CSV/APKG

### Fase 3: Conexión a la Nube (Firebase y Google Drive)
- Firebase Authentication con Google Sign-In
- Cloud Firestore con persistencia offline
- Sincronización automática
- Backup de libros en Google Drive
- Migración de datos locales a la nube

### Fase 4: Pulido y Add-on Anki
- Dark Mode de baja fatiga visual
- Selección de fuentes personalizadas
- Add-on Python para Anki
- OCR para PDFs escaneados (opcional)

## 🛠️ Tecnologías Utilizadas

- **Flutter & Dart** - Framework multiplataforma
- **BLoC Pattern** - Gestión de estado reactiva
- **Syncfusion PDF Viewer** - Lector de PDF profesional
- **Vocsy EPUB Viewer** - Lector de EPUB nativo
- **Shared Preferences** - Almacenamiento local simple

## 📝 Notas de Desarrollo

### Decisiones de Arquitectura

1. **BLoC Pattern**: Elegido por su escalabilidad y separación clara de responsabilidades
2. **Almacenamiento Local**: Shared Preferences para MVP; se migrará a SQLite en Fase 2
3. **Copia de Archivos**: Los libros se copian al directorio de la app para garantizar acceso persistente
4. **Modelos Serializables**: Preparados para facilitar la migración a Firebase en Fase 3

### Pendientes Técnicos para Fase 2

- [ ] Implementar base de datos SQLite
- [ ] Añadir funcionalidad de selección de texto
- [ ] Integrar API de diccionario
- [ ] Implementar Text-to-Speech
- [ ] Crear pantalla de vocabulario
- [ ] Desarrollar exportación a Anki

## 🐛 Problemas Conocidos

- Los warnings de `file_picker` sobre implementaciones por plataforma son normales y no afectan la funcionalidad
- El lector EPUB abre en una pantalla nativa (limitación de vocsy_epub_viewer)

## 📄 Licencia

Este proyecto está en desarrollo activo.

---

**Versión**: 1.0.0 (Fase 1)  
**Última actualización**: Noviembre 2025
