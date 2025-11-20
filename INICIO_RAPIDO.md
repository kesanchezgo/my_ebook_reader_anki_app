# 🚀 Inicio Rápido - Mi Lector Anki

## ⚡ 3 Pasos para Empezar

### 1️⃣ Instalar Dependencias (30 segundos)
```bash
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"
flutter pub get
```

### 2️⃣ Ejecutar la App (10 segundos)
```bash
flutter run
```

### 3️⃣ Importar tu Primer Libro
1. Toca el botón **+** flotante
2. Selecciona un PDF o EPUB
3. ¡Empieza a leer! 📚

---

## 📱 Guía Visual de la App

### Pantalla 1: Biblioteca Vacía
```
┌─────────────────────────────────────┐
│  ← Mi Biblioteca              🔄    │
├─────────────────────────────────────┤
│                                     │
│            📚                       │
│                                     │
│    No hay libros en tu biblioteca   │
│                                     │
│  Toca el botón + para importar tu   │
│        primer libro                 │
│                                     │
│                                     │
│                                     │
│                              ┌───┐  │
│                              │ + │  │
│                              └───┘  │
└─────────────────────────────────────┘
```

### Pantalla 2: Biblioteca con Libros
```
┌─────────────────────────────────────┐
│  ← Mi Biblioteca              🔄    │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐          │
│  │   📕    │  │   📘    │          │
│  │   PDF   │  │  EPUB   │          │
│  │ ──────  │  │ ──────  │          │
│  │ Sapiens │  │ 1984    │          │
│  │ ████░░░ │  │ ██████  │          │
│  │ 42%     │  │ 78%     │          │
│  └─────────┘  └─────────┘          │
│                                     │
│  ┌─────────┐  ┌─────────┐          │
│  │   📗    │  │   📙    │          │
│  │   PDF   │  │  EPUB   │          │
│  │ ──────  │  │ ──────  │          │
│  │ Atomic  │  │ Dune    │          │
│  │ ░░░░░░  │  │ ███░░░  │          │
│  │  0%     │  │ 25%     │          │
│  └─────────┘  └─────────┘   ┌───┐  │
│                              │ + │  │
│                              └───┘  │
└─────────────────────────────────────┘
```

### Pantalla 3: Lector de PDF
```
┌─────────────────────────────────────┐
│  ← Sapiens              📄 58 / 420 │
├─────────────────────────────────────┤
│                                     │
│  Lorem ipsum dolor sit amet,        │
│  consectetur adipiscing elit.       │
│  Sed do eiusmod tempor incididunt   │
│  ut labore et dolore magna aliqua.  │
│                                     │
│  Ut enim ad minim veniam, quis      │
│  nostrud exercitation ullamco       │
│  laboris nisi ut aliquip ex ea      │
│  commodo consequat.                 │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Texto seleccionado...       │   │
│  │ [Añadir a Anki] [Cancelar]  │   │
│  └─────────────────────────────┘   │
│                                     │
│        (Pellizca para zoom)         │
│        (Desliza para página)        │
└─────────────────────────────────────┘
```

---

## 🎮 Controles

### En la Biblioteca
| Acción | Resultado |
|--------|-----------|
| Tocar libro | Abre el lector |
| Tocar 🗑️ | Elimina libro (con confirmación) |
| Tocar + | Importa nuevo libro |
| Tocar 🔄 | Refresca la biblioteca |

### En el Lector PDF
| Acción | Resultado |
|--------|-----------|
| Deslizar → | Página siguiente |
| Deslizar ← | Página anterior |
| Pellizcar | Zoom in/out |
| Tocar ← | Volver a biblioteca |
| Long press texto | Seleccionar (preparado para Fase 2) |

### En el Lector EPUB
| Acción | Resultado |
|--------|-----------|
| Tocar pantalla | Mostrar controles |
| Deslizar → | Página siguiente |
| Deslizar ← | Página anterior |
| Menú nativo | Cambiar fuente, tamaño, etc. |

---

## 🎯 Flujo de Uso Típico

```
Abrir App
    ↓
[¿Hay libros?]
    ↓ No
Biblioteca Vacía → Tocar + → Seleccionar archivo → Libro importado
    ↓ Sí
Ver biblioteca con libros
    ↓
Tocar un libro
    ↓
Leer páginas
    ↓
[Opcional] Seleccionar texto (Fase 2)
    ↓
Cerrar lector (← o botón atrás)
    ↓
✅ Progreso guardado automáticamente
    ↓
Reabrir libro
    ↓
✅ Continúa donde lo dejaste
```

---

## 📊 Indicadores Visuales

### Tarjeta de Libro
```
┌──────────────────┐
│      📕 PDF      │ ← Tipo de archivo con icono
│   ──────────     │
│   Nombre del     │ ← Título del libro
│      Libro       │
│                  │
│  ████████░░░░░░  │ ← Barra de progreso
│  45% completado  │ ← Porcentaje leído
│                  │
│  🗑️             │ ← Botón eliminar
└──────────────────┘
```

### Estados de Carga
- 🔄 Círculo girando = Cargando
- ✅ SnackBar verde = Éxito
- ❌ SnackBar rojo = Error

---

## 🏅 Características Destacadas

### ✨ Automáticas
- ✅ Guardado de progreso al cerrar
- ✅ Restauración al abrir
- ✅ Copia de archivos (no depende del original)
- ✅ Generación de IDs únicos

### 🎨 UI/UX
- ✅ Material Design 3
- ✅ Tema claro/oscuro automático
- ✅ Animaciones suaves
- ✅ Feedback visual constante

### 📱 Multiplataforma
- ✅ Android (5.0+)
- ✅ iOS (12+)
- ✅ Web (Chrome, Edge)
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop

---

## 🔥 Tips Rápidos

### 💡 Para Importar Múltiples Libros
```
1. Toca + → Importar libro 1
2. Espera a que aparezca
3. Toca + → Importar libro 2
4. Repite cuantas veces quieras
```

### 💡 Para Organizar tu Lectura
- Los libros con más progreso aparecen igual que los nuevos
- Usa la barra de progreso para ver qué has leído
- El número de páginas te ayuda a planificar

### 💡 Para Cambiar entre Libros
```
Lector → Botón ← → Biblioteca → Tocar otro libro
```

### 💡 Para Backup Manual (Fase 3 lo hará automático)
```
Los libros están en:
Android: /data/data/com.example.../files/books/
iOS: /Library/Application Support/.../books/
```

---

## 🚨 Solución Rápida de Problemas

### "No puedo importar libros"
✅ Verifica permisos en Configuración → Apps → Mi Lector Anki → Permisos

### "El libro no abre"
✅ Asegúrate de que sea PDF o EPUB válido  
✅ Prueba con un archivo de menor tamaño primero

### "Perdí mi progreso"
✅ No debería pasar, pero intenta:
1. Cerrar la app completamente
2. Reabrirla
3. El progreso se guarda en el dispositivo

### "La app va lenta"
✅ Prueba con archivos más pequeños  
✅ En Android: Limpia caché (Configuración → Apps)  
✅ En iOS: Reinicia el dispositivo

---

## 📚 Archivos de Prueba Recomendados

### Para Empezar:
1. **Project Gutenberg** (libros gratuitos)
   - https://www.gutenberg.org/
   - Miles de PDFs y EPUBs clásicos

2. **Standard Ebooks** (EPUBs de calidad)
   - https://standardebooks.org/
   - Diseño moderno, bien formateados

3. **Tamaños Recomendados**
   - Primera prueba: < 5 MB
   - Uso normal: < 20 MB
   - EPUBs: Generalmente < 2 MB

---

## ✅ Checklist de Primera Vez

- [ ] `flutter pub get` ejecutado
- [ ] App inicia sin errores
- [ ] Veo la pantalla "Mi Biblioteca"
- [ ] Toco el botón + sin problemas
- [ ] Importo un PDF exitosamente
- [ ] El PDF se abre y leo algunas páginas
- [ ] Cierro el lector
- [ ] Veo la barra de progreso actualizada
- [ ] Reabro el libro
- [ ] ✅ Continúa donde lo dejé

---

## 🎓 Siguiente Nivel

Cuando domines la Fase 1, estarás listo para:

### Fase 2: Vocabulario
- 📝 Capturar palabras mientras lees
- 🔊 Generar audio automático
- 📚 Crear tarjetas Anki
- 📤 Exportar a Anki

### Fase 3: Nube
- ☁️ Sincronización automática
- 💾 Backup en Google Drive
- 🔐 Login con Google
- 📱 Acceso desde múltiples dispositivos

---

## 🎯 ¡Empecemos!

```bash
# Copia y pega estos comandos:
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"
flutter pub get
flutter run
```

**¡Disfruta tu nuevo lector de libros!** 📚✨

---

**Tip**: Presiona `r` mientras la app corre para hot reload después de cambios de código.
