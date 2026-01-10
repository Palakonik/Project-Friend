plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.friendapp.frontend"

    // 🔥 GÜNCELLENDİ: Hata mesajına göre 36 yapıldı
    compileSdk = 36

    // 🔥 GÜNCELLENDİ: Hata mesajına göre yeni sürüm eklendi
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"

        minSdk = flutter.minSdkVersion
        targetSdk = 34 

        versionCode = 1
        versionName = "1.0"
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