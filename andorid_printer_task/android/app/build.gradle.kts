plugins {
    id("com.android.application")
    id("kotlin-android")
    // ⚠️ Flutter plugin must come last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.andorid_printer_task"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.andorid_printer_task"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Ensure your app includes native libs (SmartPOS JNI .so files)
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    // ✅ Proper build types
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false       // Don't shrink code
            isShrinkResources = false     // ⚠️ Must be false (fixes your previous error)
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // ✅ Java & Kotlin settings
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // ✅ Make sure JNI native libraries are correctly included
    sourceSets {
        getByName("main") {
            // Where your .so files are located
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    // ✅ Avoid issues with duplicate META-INF files (sometimes needed for SmartPOS jars)
    packaging {
        resources.excludes.add("META-INF/*.kotlin_module")
        resources.excludes.add("META-INF/DEPENDENCIES")
        resources.excludes.add("META-INF/LICENSE")
        resources.excludes.add("META-INF/LICENSE.txt")
        resources.excludes.add("META-INF/NOTICE")
        resources.excludes.add("META-INF/NOTICE.txt")
    }
}

flutter {
    source = "../.."
}

// ✅ Add local SmartPOS JAR files
repositories {
    flatDir {
        dirs("libs")
    }
}

dependencies {
    implementation(files("libs/SmartPos_1.7.0_R230208.jar"))
    implementation(files("libs/core-3.2.1.jar"))
}
