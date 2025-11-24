# 📚 Mi Lector Anki (AI Powered)

Una aplicación moderna de lectura de libros (EPUB) diseñada para el aprendizaje de idiomas y la mejora de vocabulario. Integra inteligencia artificial para definiciones contextuales, traducción y generación automática de tarjetas de estudio tipo Anki.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![AI](https://img.shields.io/badge/AI-Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Fase%202%20(Activa)-success?style=for-the-badge)

---

## 🚀 Estado del Proyecto: FASE 2 (AVANZADA)

El proyecto ha superado la fase de lector básico y se encuentra en la implementación profunda de herramientas de estudio y análisis de texto.

### ✨ Funcionalidades Implementadas

#### 📖 Lector Inteligente
- **Soporte EPUB Nativo**: Renderizado fluido con `epubx` y `flutter_widget_from_html`.
- **Modos de Estudio**:
  - 🧠 **Aprender Idioma**: Traducción de oraciones y palabras al idioma nativo.
  - 📚 **Mejorar Vocabulario**: Definiciones y sinónimos en el mismo idioma.
- **Selección Contextual**: Captura inteligente de palabras y oraciones completas.

#### 🤖 Integración IA (Gemini)
- **Diccionario Contextual**: Define palabras basándose en la oración exacta donde aparecen.
- **Análisis Gramatical**: Identifica formas irregulares y lemas.
- **Generación de Ejemplos**: Crea ejemplos de uso adicionales automáticamente.

#### 📝 Sistema de Estudio (Flashcards)
- **Base de Datos Local**: Gestión eficiente con `sqflite`.
- **Tipos de Tarjetas**:
  - **Adquisición**: Para aprender nuevos idiomas (Palabra + Traducción + Audio).
  - **Enriquecimiento**: Para profundizar en el idioma nativo (Definiciones + Sinónimos).
- **Text-to-Speech (TTS)**: Pronunciación automática de palabras y oraciones.
- **Exportación**: Generación de archivos CSV compatibles con Anki y Excel.

---

## 🗺️ Roadmap de Desarrollo

### ✅ Fase 1: El Lector MVP (Completada)
- [x] Importación y gestión de biblioteca EPUB.
- [x] Renderizado de libros y navegación por capítulos.
- [x] Persistencia de progreso de lectura.
- [x] Configuración de apariencia (fuentes, temas).

### 🔄 Fase 2: Herramientas de Estudio (En Progreso / Casi Completa)
- [x] Integración con API de IA (Gemini).
- [x] Sistema de selección de texto y menú contextual.
- [x] Base de datos local para vocabulario (`sqflite`).
- [x] Generación de tarjetas con audio (TTS).
- [x] Pantalla de gestión de vocabulario ("Idiomas").
- [x] Exportación a CSV.
- [ ] Refinamiento de la interfaz de repaso (Spaced Repetition interno).

### 📅 Fase 3: Sincronización y Nube (Parcialmente Iniciada)
- [ ] Autenticación de usuarios.
- [ ] Backup en la nube (Firestore/Drive).
- [ ] Sincronización entre dispositivos.
- [x] Detección automática de idioma (Implementado con `google_mlkit`).

### 🎨 Fase 4: Pulido y Ecosistema
- [ ] Add-on oficial para Anki Desktop.
- [ ] Estadísticas avanzadas de lectura.
- [ ] Gamificación (rachas, objetivos diarios).

---

## 🛠️ Stack Tecnológico Actualizado

### Core & UI
- **Flutter & Dart**: Base del proyecto.
- **flutter_bloc**: Gestión de estado predecible y escalable.
- **Material Design 3**: Interfaz moderna y adaptativa.

### Datos & Lógica
- **sqflite**: Base de datos SQL local para tarjetas y libros.
- **shared_preferences**: Configuración ligera.
- **http**: Comunicación con APIs de IA.

### Inteligencia Artificial & Procesamiento
- **Google Generative AI**: Motor de análisis de texto.
- **flutter_tts**: Síntesis de voz multiplataforma.
- **google_mlkit_language_id**: Detección de idioma on-device.

---

## 📂 Estructura del Proyecto

```
lib/
├── bloc/                    # Lógica de negocio (BLoC)
├── config/                  # Temas y rutas
├── l10n/                    # Internacionalización (ES, EN, PT)
├── models/                  # Modelos de datos (Book, StudyCard)
├── screens/                 # Pantallas (Lector, Biblioteca, Idiomas)
├── services/                # Servicios (AI, DB, TTS, Archivos)
├── widgets/                 # Componentes UI reutilizables
└── main.dart               # Punto de entrada
```

---

## 📖 Documentación Adicional

| Documento | Descripción |
|-----------|-------------|
| **[INICIO_RAPIDO.md](INICIO_RAPIDO.md)** | Guía para empezar a usar la app. |
| **[COMO_EJECUTAR.md](COMO_EJECUTAR.md)** | Instrucciones técnicas para desarrolladores. |
| **[ARQUITECTURA.md](ARQUITECTURA.md)** | Detalles técnicos sobre BLoC y Servicios. |
| **[CHANGELOG.md](CHANGELOG.md)** | Historial de cambios y versiones. |

---

## 🤝 Contribuir

El proyecto es privado por el momento, pero se aceptan sugerencias y reportes de bugs a través de los canales oficiales.

---

**Versión**: 1.0.0+1 (Fase 2)  
**Última actualización**: Noviembre 2025
