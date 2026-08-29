import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {

    namespace = "com.ironcreze.vendor"

    // ✅ Recommended SDK versions
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // ✅ Signing configuration
    signingConfigs {

        create("release") {

            keyAlias = keystoreProperties["keyAlias"] as String

            keyPassword = keystoreProperties["keyPassword"] as String

            storeFile = file("ironcreze-key.jks")

            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // ✅ REQUIRED for flutter_local_notifications
    compileOptions {

        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17

        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {

        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {

        applicationId = "com.ironcreze.vendor"

        // ✅ REQUIRED minimum for Firebase + notifications
        minSdk = flutter.minSdkVersion

        targetSdk = 34

        versionCode = flutter.versionCode

        versionName = flutter.versionName
    }

    buildTypes {

        debug {

            isMinifyEnabled = false
        }

        release {

            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = false

            isShrinkResources = false
        }
    }
}

flutter {

    source = "../.."
}

// ✅ REQUIRED dependency for flutter_local_notifications
dependencies {

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
