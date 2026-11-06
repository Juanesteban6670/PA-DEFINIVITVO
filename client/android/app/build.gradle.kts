import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.isFile) {
    releasePropertiesFile.inputStream().use(releaseProperties::load)
}
fun releaseValue(property: String, environment: String): String? =
    System.getenv(environment)?.takeIf(String::isNotBlank)
        ?: releaseProperties.getProperty(property)?.takeIf(String::isNotBlank)

val releaseStoreFile = releaseValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = releaseValue("storePassword", "ANDROID_STORE_PASSWORD")
val releaseKeyAlias = releaseValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = releaseValue("keyPassword", "ANDROID_KEY_PASSWORD")

android {
    namespace = "com.cartagenasegura.cartagena_segura"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cartagenasegura.cartagena_segura"
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
            if (releaseStoreFile != null) storeFile = file(releaseStoreFile)
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

tasks.configureEach {
    if (name.contains("Release", ignoreCase = true)) {
        doFirst {
            val keystore = releaseStoreFile?.let(::file)
            if (keystore == null || !keystore.isFile ||
                releaseStorePassword == null || releaseKeyAlias == null ||
                releaseKeyPassword == null) {
                throw GradleException(
                    "Configura ANDROID_KEYSTORE_PATH, ANDROID_STORE_PASSWORD, ANDROID_KEY_ALIAS y ANDROID_KEY_PASSWORD, o mobile/android/key.properties. No se usa firma debug para release.",
                )
            }
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
