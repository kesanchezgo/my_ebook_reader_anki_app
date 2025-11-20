# 📚 Mi Lector Anki

Una aplicación multiplataforma de lectura de libros (PDF/EPUB) con integración avanzada para capturar vocabulario y exportarlo a Anki, diseñada para reducir la fatiga visual.

---

## 🎉 Estado Actual: FASE 1 COMPLETADA ✅

La aplicación está **100% funcional** con todas las características básicas de un lector de libros implementadas.

### ✨ Funcionalidades Actuales

✅ Importar libros PDF y EPUB  
✅ Biblioteca visual con cuadrícula de libros  
✅ Lector profesional de PDF (Syncfusion)  
✅ Lector nativo de EPUB (Vocsy)  
✅ Guardado automático de progreso  
✅ Gestión de biblioteca (añadir/eliminar)  
✅ Indicadores de progreso de lectura  
✅ Soporte multiplataforma (iOS, Android, Web, Desktop)  

---

## 🚀 Inicio Rápido

### Opción 1: Lectura Rápida (2 minutos)
👉 Lee **[INICIO_RAPIDO.md](INICIO_RAPIDO.md)** para empezar inmediatamente

### Opción 2: Documentación Completa
1. **[COMO_EJECUTAR.md](COMO_EJECUTAR.md)** - Guía detallada de ejecución
2. **[FASE1_COMPLETADA.md](FASE1_COMPLETADA.md)** - Detalles de implementación
3. **[ARQUITECTURA.md](ARQUITECTURA.md)** - Arquitectura del proyecto

---

## 📖 Índice de Documentación

| Documento | Descripción | Para Quién |
|-----------|-------------|------------|
| **[INICIO_RAPIDO.md](INICIO_RAPIDO.md)** | Guía visual de 3 pasos | 👤 Usuarios nuevos |
| **[COMO_EJECUTAR.md](COMO_EJECUTAR.md)** | Instrucciones completas de ejecución | 👨‍💻 Desarrolladores |
| **[FASE1_README.md](FASE1_README.md)** | Visión general y roadmap | 📋 Gestores de proyecto |
| **[FASE1_COMPLETADA.md](FASE1_COMPLETADA.md)** | Logros y métricas de Fase 1 | ✅ Revisores |
| **[RESUMEN_FASE1.md](RESUMEN_FASE1.md)** | Resumen ejecutivo completo | 📊 Stakeholders |
| **[ARQUITECTURA.md](ARQUITECTURA.md)** | Arquitectura BLoC detallada | 🏗️ Arquitectos |
| **[CONFIGURACION_PERMISOS.md](CONFIGURACION_PERMISOS.md)** | Permisos Android/iOS | 🔐 DevOps |

---

## 💻 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK 3.10.0 o superior
- Android Studio / VS Code
- Emulador o dispositivo físico

### Comandos Básicos

```bash
# 1. Navegar al proyecto
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la aplicación
flutter run

# 4. (Opcional) Ejecutar en dispositivo específico
flutter run -d chrome        # Web
flutter run -d windows       # Windows Desktop
flutter run -d android       # Android
```

---

## 🏗️ Arquitectura

El proyecto utiliza el patrón **BLoC (Business Logic Component)** para una separación clara entre UI y lógica de negocio.

```
┌─────────────┐
│     UI      │  Muestra estados
│  (Screens)  │
└──────┬──────┘
       │ Dispara eventos
       ↓
┌─────────────┐
│    BLoC     │  Procesa lógica
│ (Business)  │
└──────┬──────┘
       │ Usa servicios
       ↓
┌─────────────┐
│  Services   │  Accede a datos
│   (Local)   │
└─────────────┘
```

**Ver más**: [ARQUITECTURA.md](ARQUITECTURA.md)

---

## 📂 Estructura del Proyecto

```
lib/
├── bloc/                    # Gestión de estado (BLoC)
├── models/                  # Modelos de datos
├── screens/                 # Pantallas de la app
├── services/                # Servicios (storage, files)
├── widgets/                 # Widgets reutilizables
└── main.dart               # Punto de entrada
```

---

## 🛠️ Stack Tecnológico

### Core
- **Flutter** - Framework multiplataforma
- **Dart** - Lenguaje de programación

### Gestión de Estado
- **flutter_bloc** - Patrón BLoC
- **equatable** - Comparación de objetos

### Lectores
- **syncfusion_flutter_pdfviewer** - Visor PDF profesional
- **vocsy_epub_viewer** - Visor EPUB nativo

### Almacenamiento
- **shared_preferences** - Almacenamiento local
- **path_provider** - Directorios del sistema

### Utilidades
- **file_picker** - Selector de archivos
- **uuid** - IDs únicos

---

## 📱 Plataformas Soportadas

| Plataforma | Estado | Versión Mínima |
|------------|--------|----------------|
| **Android** | ✅ Completo | Android 5.0 (API 21) |
| **iOS** | ✅ Completo | iOS 12.0 |
| **Web** | ✅ Funcional | Chrome, Edge |
| **Windows** | ✅ Funcional | Windows 10+ |
| **macOS** | ✅ Funcional | macOS 10.14+ |
| **Linux** | ✅ Funcional | Ubuntu 20.04+ |

---

## 🎯 Roadmap del Proyecto

### ✅ Fase 1: El Lector MVP Local (COMPLETADA)
- ✅ Importación de libros PDF y EPUB
- ✅ Biblioteca de libros
- ✅ Lectores funcionales
- ✅ Guardado de progreso local

### 🔄 Fase 2: Integración de Vocabulario Local (Siguiente)
- [ ] Base de datos SQLite
- [ ] Captura de palabras al leer
- [ ] API de diccionario automático
- [ ] Text-to-Speech para audio
- [ ] Pantalla de vocabulario
- [ ] Exportación a Anki (CSV/APKG)

### 📅 Fase 3: Conexión a la Nube
- [ ] Firebase Authentication
- [ ] Cloud Firestore (offline-first)
- [ ] Google Drive backup
- [ ] Sincronización automática
- [ ] Migración de datos locales

### 🎨 Fase 4: Pulido y Add-on Anki
- [ ] Dark Mode de baja fatiga visual
- [ ] Fuentes personalizadas
- [ ] Add-on Python para Anki
- [ ] OCR para PDFs escaneados (opcional)

---

## 🧪 Testing

### Ejecutar Tests
```bash
flutter test
```

### Tests Incluidos
- ✅ Test de inicialización de la app
- ✅ Test de pantalla principal

---

## 📊 Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| **Líneas de Código** | ~1,126 |
| **Archivos Dart** | 11 |
| **Dependencias** | 8 |
| **Pantallas** | 2 |
| **Servicios** | 2 |
| **Plataformas** | 6 |

---

## 🎓 Guías y Tutoriales

### Para Usuarios
1. [Inicio Rápido](INICIO_RAPIDO.md) - Empieza en 3 pasos
2. [Cómo Usar la App](INICIO_RAPIDO.md#-guía-visual-de-la-app) - Guía visual

### Para Desarrolladores
1. [Cómo Ejecutar](COMO_EJECUTAR.md) - Instalación y ejecución
2. [Arquitectura](ARQUITECTURA.md) - Patrones y diseño
3. [Configuración](CONFIGURACION_PERMISOS.md) - Permisos por plataforma

---

## 🐛 Solución de Problemas

### Problemas Comunes

**"Permission denied" al importar libros**
```
Solución: Ir a Configuración → Apps → Mi Lector Anki 
         → Permisos → Activar "Archivos y multimedia"
```

**"Could not find package"**
```bash
flutter clean
flutter pub get
```

**La app no inicia**
```bash
flutter doctor -v
# Resolver cualquier problema que muestre
```

**Ver más**: [COMO_EJECUTAR.md - Solución de Problemas](COMO_EJECUTAR.md#-solución-de-problemas)

---

## 🤝 Contribuir

Este proyecto está en desarrollo activo. Las contribuciones son bienvenidas para:

- 🐛 Reportar bugs
- ✨ Sugerir nuevas funcionalidades
- 📝 Mejorar documentación
- 🧪 Añadir tests

---

## 📄 Licencia

Este proyecto está en desarrollo privado.

---

## 📞 Contacto y Soporte

Para preguntas o problemas:
1. Revisa la documentación en los archivos MD
2. Verifica la sección de solución de problemas
3. Consulta los logs con `flutter run -v`

---

## 🌟 Características Destacadas

### 🎨 UI/UX Moderna
- Material Design 3
- Tema claro/oscuro automático
- Animaciones fluidas
- Feedback visual constante

### ⚡ Rendimiento
- Hot reload para desarrollo rápido
- Guardado eficiente con SharedPreferences
- Lectores optimizados nativos

### 📱 Multiplataforma
- Código único para 6 plataformas
- Experiencia nativa en cada una
- Adaptación automática a pantallas

### 🔒 Privacidad
- Datos 100% locales (Fase 1)
- Sin registro requerido
- Sin conexión a internet necesaria

---

## 🎯 Siguiente Paso

¿Listo para empezar?

1. **Usuarios**: Lee [INICIO_RAPIDO.md](INICIO_RAPIDO.md)
2. **Desarrolladores**: Lee [COMO_EJECUTAR.md](COMO_EJECUTAR.md)
3. **Arquitectos**: Lee [ARQUITECTURA.md](ARQUITECTURA.md)

---

## ✨ ¡Empieza Ahora!

```bash
flutter pub get && flutter run
```

**¡Disfruta leyendo! 📚**

---

**Versión**: 1.0.0 - Fase 1 Completada  
**Última actualización**: Noviembre 2025  
**Estado**: ✅ Producción
