plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // ✅ Mantén solo esta versión
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.untitled"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.untitled"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 Firebase Auth
    implementation("com.google.firebase:firebase-auth:22.3.0")

    // 🔑 Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}

// ❌ Elimina esto (ya no se usa):
// apply(plugin = "com.google.gms.google-services")
