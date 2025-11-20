# 🚀 Guía de Ejecución - Mi Lector Anki (Fase 1)

## ✅ Pre-requisitos

Antes de ejecutar la aplicación, asegúrate de tener:

- ✅ Flutter SDK (3.10.0 o superior)
- ✅ Android Studio / VS Code con extensiones de Flutter
- ✅ Emulador Android / Dispositivo iOS / Navegador Chrome

## 📱 Paso 1: Verificar Instalación de Flutter

```bash
flutter doctor -v
```

Debes ver todas las marcas en verde (✓). Si hay problemas, sigue las instrucciones que te da Flutter.

## 📦 Paso 2: Instalar Dependencias

```bash
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"
flutter pub get
```

Deberías ver el mensaje: `Got dependencies!`

## 🔍 Paso 3: Verificar Dispositivos Disponibles

```bash
flutter devices
```

Esto mostrará todos los dispositivos/emuladores disponibles:
- Android emulators
- iOS simulators (solo en macOS)
- Chrome
- Edge
- Windows desktop

## ▶️ Paso 4: Ejecutar la Aplicación

### Opción A: Modo Debug (Recomendado para desarrollo)

```bash
# Para ejecutar en cualquier dispositivo disponible
flutter run

# Para ejecutar en un dispositivo específico
flutter run -d <device-id>

# Ejemplos:
flutter run -d chrome
flutter run -d windows
flutter run -d emulator-5554
```

### Opción B: Modo Release (Para pruebas de rendimiento)

```bash
flutter run --release
```

## 🎯 Paso 5: Probar las Funcionalidades

Una vez que la app esté corriendo:

### 1. Importar un Libro
   - Toca el botón flotante **"+"** (esquina inferior derecha)
   - Selecciona un archivo PDF o EPUB de tu dispositivo
   - Espera a que el libro aparezca en la biblioteca

### 2. Abrir un Libro
   - Toca cualquier tarjeta de libro en la cuadrícula
   - El lector se abrirá automáticamente
   - Para **PDF**: Desliza para cambiar de página, pellizca para zoom
   - Para **EPUB**: Usa los controles nativos

### 3. Verificar Guardado de Progreso
   - Lee algunas páginas
   - Cierra el lector (botón atrás)
   - Vuelve a abrir el mismo libro
   - ✅ Deberías ver que regresa a la última página leída

### 4. Eliminar un Libro
   - En la biblioteca, toca el icono de basura en una tarjeta
   - Confirma la eliminación
   - El libro desaparecerá de la biblioteca

## 🛠️ Comandos Útiles de Flutter

### Limpiar el proyecto
```bash
flutter clean
flutter pub get
```

### Actualizar dependencias
```bash
flutter pub upgrade
```

### Ver logs detallados
```bash
flutter run -v
```

### Hot Reload (mientras la app está corriendo)
Presiona `r` en la terminal o usa el botón en tu IDE

### Hot Restart (mientras la app está corriendo)
Presiona `R` en la terminal o usa el botón en tu IDE

### Detener la aplicación
Presiona `q` en la terminal

## 🐛 Solución de Problemas

### Error: "No pubspec.yaml file found"
**Solución**: Asegúrate de estar en el directorio correcto
```bash
cd "d:\Proyectos\OTROS\book-lector-anki-v2\my_ebook_reader_anki_app"
```

### Error: "Could not find package"
**Solución**: Limpia y reinstala dependencias
```bash
flutter clean
flutter pub get
```

### Error: "Gradle build failed" (Android)
**Solución**: 
1. Abre Android Studio
2. File → Invalidate Caches / Restart
3. Intenta nuevamente

### Error: "Unable to load asset" (Libros no se ven)
**Solución**: Esto es normal en la primera ejecución. Importa un libro desde el dispositivo.

### Error: "Permission denied" al importar libros
**Solución** (Android):
1. Ve a Configuración del dispositivo
2. Apps → Mi Lector Anki → Permisos
3. Activa "Archivos y multimedia"

### La app no inicia en Windows
**Solución**:
```bash
flutter config --enable-windows-desktop
flutter create .
flutter run -d windows
```

## 📊 Verificar que Todo Funciona

Checklist de funcionalidades:

- [ ] La app inicia sin errores
- [ ] Se muestra la pantalla de biblioteca vacía
- [ ] El botón "+" abre el selector de archivos
- [ ] Se puede importar un PDF
- [ ] Se puede importar un EPUB
- [ ] Los libros aparecen en la cuadrícula
- [ ] Se puede abrir y leer un PDF
- [ ] Se puede abrir y leer un EPUB
- [ ] El progreso se guarda al cerrar
- [ ] El progreso se restaura al abrir
- [ ] Se puede eliminar un libro
- [ ] La barra de progreso se actualiza

## 🎨 Para Desarrollo

### Modo Debug con Inspector
```bash
flutter run --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### Ver estructura de widgets (mientras corre)
Presiona `w` en la terminal

### Ver rendimiento
Presiona `p` en la terminal

## 📱 Ejecutar en Diferentes Plataformas

### Android
```bash
# Emulador
flutter emulators --launch <emulator_id>
flutter run

# Dispositivo físico (conectado por USB)
flutter devices
flutter run -d <device-id>
```

### iOS (solo macOS)
```bash
# Simulador
open -a Simulator
flutter run

# Dispositivo físico
flutter run -d <device-id>
```

### Web
```bash
flutter run -d chrome
# o
flutter run -d edge
```

### Windows Desktop
```bash
flutter run -d windows
```

## 🔥 Hot Tips

1. **Usa Hot Reload (r)**: Para cambios de UI sin perder el estado
2. **Usa Hot Restart (R)**: Cuando cambies el estado inicial o constantes
3. **Usa DevTools**: `flutter pub global activate devtools` y luego `flutter pub global run devtools`
4. **Logs**: Usa `print()` o `debugPrint()` para depurar

## 📝 Próximos Pasos

Cuando la Fase 1 esté funcionando correctamente:

✅ Verifica que todas las funcionalidades básicas funcionan  
✅ Prueba en diferentes dispositivos/plataformas  
✅ Importa varios libros de diferentes tipos  
✅ Verifica el guardado de progreso  

**¡Listo para comenzar la Fase 2!** 🎉

---

## 💡 Consejos para Pruebas

### Archivos de Prueba Recomendados:
- Busca PDFs gratuitos en: [Project Gutenberg](https://www.gutenberg.org/)
- Descarga EPUBs de prueba de: [Standard Ebooks](https://standardebooks.org/)

### Tamaños Recomendados para Pruebas:
- PDFs pequeños (< 5 MB): Para pruebas rápidas
- PDFs medianos (5-20 MB): Para pruebas de rendimiento
- EPUBs: Generalmente son ligeros (< 2 MB)

## 🎯 Objetivo de la Fase 1

Al finalizar estas pruebas, deberías tener:

✅ Una biblioteca funcional  
✅ Capacidad de importar libros  
✅ Lectores de PDF y EPUB funcionando  
✅ Guardado automático de progreso  
✅ Interfaz intuitiva y fluida  

**¡Disfruta tu lector de libros!** 📚
