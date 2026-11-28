import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read the root .env file without exposing it to Git.
val admobEnvFile = rootProject.file("../.env")
val admobEnv = Properties().apply {
    if (admobEnvFile.exists()) {
        admobEnvFile.readLines().forEach { line ->
            val entry = line.substringBefore("#").trim()
            val separator = entry.indexOf("=")
            if (separator > 0) {
                setProperty(
                    entry.substring(0, separator).trim(),
                    entry.substring(separator + 1).trim()
                )
            }
        }
    }
}
val admobApplicationId = admobEnv.getProperty("ADMOB_ANDROID_APP_ID")
    ?.takeIf { it.isNotBlank() }
    ?: "ca-app-pub-3940256099942544~3347511713"


android {
    namespace = "com.example.documind_ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aminemtar.documind"
        manifestPlaceholders["admobAppId"] = admobApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // AdMob needs Android 6.0 (API 23) or newer.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
