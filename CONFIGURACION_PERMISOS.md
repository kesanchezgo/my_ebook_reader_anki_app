# 📱 Configuración de Permisos por Plataforma

## Android

### Permisos Necesarios

Edita el archivo `android/app/src/main/AndroidManifest.xml` y añade estos permisos:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permisos para Fase 1 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Para Android 11 y superior -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>

    <application
        android:label="Mi Lector Anki"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
        
        <!-- Resto de tu configuración -->
        
    </application>
</manifest>
```

### Versión Mínima de Android

En `android/app/build.gradle.kts`, asegúrate de tener:

```kotlin
android {
    defaultConfig {
        minSdk = 21
        targetSdk = 34
    }
}
```

---

## iOS

### Permisos en Info.plist

Edita el archivo `ios/Runner/Info.plist` y añade estas entradas:

```xml
<dict>
    <!-- Permisos para acceso a archivos -->
    <key>UISupportsDocumentBrowser</key>
    <true/>
    
    <!-- Descripción para el usuario -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Necesitamos acceso para importar libros desde tus archivos</string>
    
    <key>NSDocumentPickerUsageDescription</key>
    <string>Necesitamos acceso para seleccionar libros PDF y EPUB</string>
    
    <!-- Permitir HTTP para API de diccionario (Fase 2) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    
    <!-- Resto de tu configuración -->
</dict>
```

### Versión Mínima de iOS

En `ios/Podfile`, asegúrate de tener:

```ruby
platform :ios, '12.0'
```

---

## 🧪 Prueba la Aplicación

### En Android:
```bash
flutter run -d android
```

### En iOS:
```bash
flutter run -d ios
```

### En Chrome (Web):
```bash
flutter run -d chrome
```

### En Windows:
```bash
flutter run -d windows
```

---

## 🐛 Solución de Problemas Comunes

### Error: "Permission denied" en Android

**Solución**: 
1. Ve a Configuración del dispositivo
2. Apps → Mi Lector Anki → Permisos
3. Activa "Archivos y multimedia"

### Error: "Could not open file" en iOS

**Solución**: 
1. Verifica que Info.plist tenga las claves correctas
2. Ejecuta `flutter clean` y `flutter pub get`
3. En Xcode, limpia el build (Product → Clean Build Folder)

### La app no encuentra los libros importados

**Solución**: 
- Los libros se guardan en el directorio de la app
- Usa `path_provider` para obtener la ruta correcta
- Verifica con: `print(await getApplicationDocumentsDirectory());`

---

## 📝 Notas Adicionales

### Para Producción (Release Build):

#### Android:
```bash
flutter build apk --release
```

#### iOS:
```bash
flutter build ios --release
```

### Iconos de la App

Reemplaza los iconos en:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Puedes usar herramientas como [App Icon Generator](https://appicon.co/) para generar todos los tamaños.

---

## 🔐 Permisos para Futuras Fases

### Fase 2 (Vocabulario Local):
- No requiere permisos adicionales
- TTS usa permisos del sistema

### Fase 3 (Firebase y Google Drive):
```xml
<!-- Android -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

```xml
<!-- iOS -->
<key>NSInternetUsageDescription</key>
<string>Necesitamos internet para sincronizar tus datos y hacer backup</string>
```
