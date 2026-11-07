// Configuración de Gradle del proyecto Android (plantilla de Flutter).

// Dónde está el SDK de Flutter: lo dice local.properties, que Flutter escribe en
// cada computador y no se sube al repositorio. De ahí se cargan sus herramientas.
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) {
                "falta flutter.sdk en local.properties: ejecute flutter pub get en frontend"
            }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // De dónde se descargan los complementos de Gradle.
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Versiones fijas de las herramientas de Android y de Kotlin (constitución §2,
// Dependencias). Algunos paquetes se quedan en versiones anteriores porque las
// nuevas exigen herramientas más nuevas (razones en pubspec.yaml).
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// El único módulo propio: la app (android/app).
include(":app")
