# 🗺️ Roadmap del Proyecto

Este documento detalla el plan de desarrollo y el estado actual de cada fase del proyecto **Mi Lector Anki**.

---

## ✅ Fase 1: El Lector MVP (Completada)
**Objetivo:** Crear un lector de libros funcional y robusto.

- [x] **Gestión de Archivos**
  - Importación de archivos `.epub` y `.pdf`.
  - Copia local de archivos al directorio de la aplicación.
  - Eliminación de libros y limpieza de archivos.
- [x] **Biblioteca**
  - Visualización en cuadrícula con portadas generadas.
  - Persistencia de metadatos (título, autor, ruta).
- [x] **Lector**
  - Renderizado de EPUB con `epubx`.
  - Renderizado de PDF con `syncfusion_flutter_pdfviewer`.
  - Navegación por capítulos y páginas.
  - Guardado automático de la posición de lectura.
- [x] **UI/UX**
  - Diseño Material 3.
  - Tema claro/oscuro.

---

## ✅ Fase 2: Herramientas de Estudio (Activa/Completada)
**Objetivo:** Integrar herramientas de análisis de texto y creación de vocabulario.

- [x] **Integración IA**
  - Conexión con Google Gemini API.
  - Prompt engineering para definiciones contextuales.
  - Análisis gramatical y detección de lemas.
- [x] **Modos de Estudio**
  - **Modo Adquisición (Idiomas):** Traducción y aprendizaje de nuevos idiomas.
  - **Modo Enriquecimiento (Nativo):** Definiciones y sinónimos en el mismo idioma.
- [x] **Base de Datos**
  - Implementación de SQLite (`sqflite`).
  - Modelado de `StudyCard` para almacenar vocabulario.
- [x] **Interacción**
  - Menú contextual al seleccionar texto.
  - Modal de edición de tarjetas antes de guardar.
  - Generación de audio (TTS) para palabras y oraciones.
- [x] **Gestión de Vocabulario**
  - Pantalla "Idiomas" para tarjetas de adquisición.
  - Pantalla "Vocabulario" para tarjetas de enriquecimiento.
  - Buscador y filtros.
- [x] **Exportación**
  - Generación de CSV compatible con Anki.

---

## 🔄 Fase 3: Sincronización y Nube (En Progreso)
**Objetivo:** Permitir el respaldo y la sincronización entre dispositivos.

- [x] **Detección de Idioma**
  - Implementación de `google_mlkit_language_id` para detectar el idioma del libro automáticamente.
- [ ] **Autenticación**
  - Login con Google/Email (Firebase Auth).
- [ ] **Base de Datos en la Nube**
  - Sincronización de `StudyCard` con Firestore.
  - Respaldo de progreso de lectura.
- [ ] **Almacenamiento de Archivos**
  - Respaldo de libros EPUB en Google Drive o Firebase Storage.

---

## 📅 Fase 4: Ecosistema y Pulido (Futuro)
**Objetivo:** Refinar la experiencia y expandir la integración.

- [ ] **Add-on de Anki**
  - Script de Python para sincronización directa con Anki Desktop.
- [ ] **Gamificación**
  - Estadísticas de lectura (tiempo, palabras leídas).
  - Rachas de estudio diarias.
- [ ] **Accesibilidad**
  - Soporte completo para lectores de pantalla.
  - Fuentes específicas para dislexia.
- [ ] **Optimización**
  - Reducción del tamaño de la app.
  - Mejora del rendimiento en libros muy grandes (>50MB).

---

**Estado Global:** El proyecto se encuentra finalizando la **Fase 2** e iniciando tareas de la **Fase 3**.
