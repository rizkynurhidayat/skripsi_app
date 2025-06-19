import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.skripsi_app"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.skripsi_app"
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
            // signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled  = false
            isShrinkResources  = false
            
            signingConfig = signingConfigs.getByName("release")

        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.12.0")

}



// import java.util.Properties
// import java.io.FileInputStream

// plugins {
//     id ("com.android.application")
//     // START: FlutterFire Configuration
//     id ("com.google.gms.google-services")
//     // END: FlutterFire Configuration
//     id ("kotlin-android")
//     id ("dev.flutter.flutter-gradle-plugin")
// }

// def localProperties = new Properties()
// def localPropertiesFile = rootProject.file('local.properties')
// if (localPropertiesFile.exists()) {
//     localPropertiesFile.withReader('UTF-8') { reader ->
//         localProperties.load(reader)
//     }
// }

// def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
// if (flutterVersionCode == null) {
//     flutterVersionCode = '1'
// }

// def flutterVersionName = localProperties.getProperty('flutter.versionName')
// if (flutterVersionName == null) {
//     flutterVersionName = '1.0'
// }

// val keystoreProperties = Properties()
// val keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// }

// android {
//     namespace "com.example.skripsi_app"
//     compileSdk 35
//     ndkVersion flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility JavaVersion.VERSION_1_8
//         targetCompatibility JavaVersion.VERSION_1_8
//     }

//     kotlinOptions {
//         jvmTarget = '1.8'
//     }

//     sourceSets {
//         main.java.srcDirs += 'src/main/kotlin'
//     }

//     defaultConfig {
//         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//         applicationId "com.example.skripsi_app"
//         multiDexEnabled true
//         // You can update the following values to match your application needs.
//         // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
//         minSdkVersion flutter.minSdkVersion
//         targetSdkVersion flutter.targetSdkVersion
//         versionCode flutterVersionCode.toInteger()
//         versionName flutterVersionName
//     }

//     signingConfigs {
//         create("release") {
//             keyAlias = keystoreProperties["keyAlias"] as String
//             keyPassword = keystoreProperties["keyPassword"] as String
//             storeFile = keystoreProperties["storeFile"]?.let { file(it) }
//             storePassword = keystoreProperties["storePassword"] as String
//         }
//     }
//     buildTypes {
//         release {
//             // TODO: Add your own signing config for the release build.
//             // Signing with the debug keys for now, so `flutter run --release` works.
//             // signingConfig signingConfigs.debug
//             minifyEnabled false
//             shrinkResources false
//             // signingConfig signingConfigs.debug
//             signingConfig = signingConfigs.getByName("release")
//         }
//     }
// }

// flutter {
//     source '../..'
// }

// dependencies {
//     implementation("androidx.multidex:multidex:2.0.1")
//     implementation("com.google.android.material:material:1.12.0")

// }
