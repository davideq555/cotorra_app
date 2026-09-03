pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // Piseamos el Kotlin embebido de Flutter (2.0.0) para leer metadatos
    // de kotlin-stdlib ≥2.2 (umbral "warn" del DependencyVersionChecker de
    // Flutter 3.44: 2.2.20). Versiones < 2.0.0 dan error; 2.0.x solo warning.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
