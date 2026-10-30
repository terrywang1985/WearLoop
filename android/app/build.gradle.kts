import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credentials stay outside source control. Environment variables take precedence.
val signingPropertiesPath = System.getenv("WEARLOOP_KEY_PROPERTIES")
val signingPropertiesFile = signingPropertiesPath?.let { file(it) }
    ?: rootProject.file("key.properties")
val signingProperties = Properties().apply {
    if (signingPropertiesFile.isFile) {
        signingPropertiesFile.inputStream().use { load(it) }
    }
}
fun signingValue(property: String, environment: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: signingProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val releaseStorePath = signingValue("storeFile", "WEARLOOP_STORE_FILE")
val releaseStoreFile = releaseStorePath?.let { path ->
    val candidate = File(path)
    if (candidate.isAbsolute) candidate else File(signingPropertiesFile.parentFile, path)
}
val releaseStorePassword = signingValue("storePassword", "WEARLOOP_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "WEARLOOP_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "WEARLOOP_KEY_PASSWORD")
val releaseSigningReady = releaseStoreFile?.isFile == true &&
    releaseStorePassword != null && releaseKeyAlias != null && releaseKeyPassword != null

if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
    check(releaseSigningReady) {
        "WearLoop release signing is not configured. Supply an upload keystore via " +
            "WEARLOOP_KEY_PROPERTIES or android/key.properties, or the WEARLOOP_STORE_FILE, " +
            "WEARLOOP_STORE_PASSWORD, WEARLOOP_KEY_ALIAS and WEARLOOP_KEY_PASSWORD environment variables. " +
            "Debug signing is never used for release builds."
    }
}

android {
    namespace = "com.wearloop.wearloop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wearloop.wearloop"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseStoreFile
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
