import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Google Play (docs/Pubblicazione.md §3.2). android/key.properties and the
// keystore are never committed. Without them, release APKs (`flutter run --release`) are
// signed with the debug key for local testing, while the App Bundle for the store refuses to
// build (see the bundleRelease check below).
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasUploadKey) FileInputStream(keystorePropertiesFile).use { load(it) }
}

android {
    namespace = "org.antaresnet.eventi_in_tasca"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.antaresnet.eventi_in_tasca"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // From `version:` in pubspec.yaml (name+build number).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
        }
    }
}

// The store bundle must never be signed with the debug key. The check runs at configuration
// time: a doFirst on bundleRelease would come after the bundle had already been written.
if (!hasUploadKey && gradle.startParameter.taskNames.any { it.endsWith("bundleRelease") }) {
    throw GradleException(
        "android/key.properties mancante: l'App Bundle per Google Play va firmato con " +
            "la chiave di caricamento (docs/Pubblicazione.md §3.2).",
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
