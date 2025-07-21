import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val versionsProperties = Properties()
val versionsPropertiesFile = File(rootProject.projectDir, "versions.properties")

if (versionsPropertiesFile.exists()) {
    versionsProperties.load(FileInputStream(versionsPropertiesFile))
} else {
    throw GradleException("Файл 'versions.properties' не найден. Убедитесь, что он существует по пути 'android/versions.properties'")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.i_rm.poteu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        languageVersion = "1.9"
        apiVersion = "1.9"
        freeCompilerArgs += listOf(
            "-opt-in=kotlin.RequiresOptIn"
        )
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.i_rm.poteu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
           signingConfig = signingConfigs.getByName("release")
        }
    }

    flavorDimensions.add("default")
    
    productFlavors {
        create("poteu") {
            dimension = "default"
            applicationIdSuffix = ".poteu"
            resValue("string", "app_name", "ПОТЭЭ-903н-2022")
            versionCode = versionsProperties["POTEU_VERSION_CODE"].toString().toInt()
            versionName = versionsProperties["POTEU_VERSION_NAME"] as String
        }
        create("height_rules") {
            dimension = "default"
            applicationId = "com.i_rm.height_rules"
            resValue("string", "app_name", "782н")
            versionCode = versionsProperties["HEIGHT_VERSION_CODE"].toString().toInt()
            versionName = versionsProperties["HEIGHT_VERSION_NAME"] as String
        }
        create("pteep") {
            dimension = "default"
            applicationIdSuffix = ".pteep"
            resValue("string", "app_name", "ПТЭЭП")
            versionCode = versionsProperties["PTEEP_VERSION_CODE"].toString().toInt()
            versionName = versionsProperties["PTEEP_VERSION_NAME"] as String
        }
        create("fz116") {
            dimension = "default"
            applicationIdSuffix = ".fz116"
            resValue("string", "app_name", "116-ФЗ")
            versionCode = versionsProperties["FZ116_VERSION_CODE"].toString().toInt()
            versionName = versionsProperties["FZ116_VERSION_NAME"] as String
        }                
    }

}

flutter {
    source = "../.."
}
