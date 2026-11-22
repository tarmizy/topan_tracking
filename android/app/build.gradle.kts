plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystore = providers.environmentVariable("TOPAN_ANDROID_KEYSTORE")

android {
    namespace = "com.topan.topan_tracking"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.topan.topan_tracking"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeystore.isPresent) {
            create("topanRelease") {
                storeFile = file(releaseKeystore.get())
                storePassword = providers.environmentVariable("TOPAN_ANDROID_STORE_PASSWORD").get()
                keyAlias = providers.environmentVariable("TOPAN_ANDROID_KEY_ALIAS").get()
                keyPassword = providers.environmentVariable("TOPAN_ANDROID_KEY_PASSWORD").get()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseKeystore.isPresent) "topanRelease" else "debug"
            )
        }
    }
}

flutter {
    source = "../.."
}
