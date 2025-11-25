plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_ebook_reader_anki_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ApplicationId por defecto (se sobrescribe por flavors)
        applicationId = "com.example.my_ebook_reader_anki_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Añadimos dimension y productFlavors
    flavorDimensions += "app"

    productFlavors {
        create("prod") {
            dimension = "app"
            // Package name de producción (lexio)
            applicationId = "com.kivara.lexio"
            // Puedes añadir resources específicos o suffix de versión
        }
        create("dev") {
            dimension = "app"
            // Package name de desarrollo (no sobrescribirá prod)
            applicationId = "com.kivara.lexio.dev"
            versionNameSuffix = "-dev"
            // opcional: applicationIdSuffix = ".dev" // ya estamos definiendo applicationId distinto
        }
    }

    buildTypes {
        getByName("debug") {
            // opcional: si quieres un sufijo para debug además del flavor
            // applicationIdSuffix = ".debug"
        }
        getByName("release") {
            // Por ahora usa debug signing (cámbialo cuando firmes)
            signingConfig = signingConfigs.getByName("debug")
            // minifyEnabled true // si activas R8/ProGuard, añade reglas
        }
    }
}

flutter {
    source = "../.."
}
