plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.fusionlkitsolution.myclassteacher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Signing configuration
    signingConfigs {
        create("release") {
            keyAlias = project.findProperty("MYAPP_UPLOAD_KEY_ALIAS") as String? ?: "methumlosath"
            keyPassword = project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as String? ?: "KLAirsr!@32025"
            storeFile = file("../../myclassteacher.jks")
            storePassword = project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as String? ?: "KLAirsr!@32025"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    // Enable build optimizations
    buildFeatures {
        buildConfig = true
        // Disable unnecessary features for size reduction
        viewBinding = false
        dataBinding = false
        compose = false
    }
    
    // Advanced size reduction configurations
    packagingOptions {
        // Exclude unnecessary files
        exclude("META-INF/DEPENDENCIES")
        exclude("META-INF/LICENSE")
        exclude("META-INF/LICENSE.txt")
        exclude("META-INF/license.txt")
        exclude("META-INF/NOTICE")
        exclude("META-INF/NOTICE.txt")
        exclude("META-INF/notice.txt")
        exclude("META-INF/ASL2.0")
        exclude("META-INF/*.kotlin_module")
        exclude("META-INF/*.version")
        
        // Exclude debug symbols for release builds
        exclude("**/lib/*/libc++_shared.so")
        exclude("**/lib/*/libjsc.so")
        
        // Pick only one architecture for size reduction
        pickFirst("**/lib/*/libc++_shared.so")
        pickFirst("**/lib/*/libjsc.so")
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fusionlkitsolution.myclassteacher"
        // You can update the following values to match your application needs.
        // For more information, see: https://developer.android.com/studio/build/application-id.html.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large apps
        multiDexEnabled = true
        
        // Advanced size reduction configurations
        ndk {
            // Specify only necessary ABIs for size reduction
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
        
        // Resource shrinking configuration
        resConfigs("en", "si") // Keep only English and Sinhala resources
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            // Debug optimizations
            isJniDebuggable = true
            isRenderscriptDebuggable = true
        }
        getByName("release") {
            // Use the release signing config for production builds
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
            
            // Advanced size reduction
            isCrunchPngs = true
            isZipAlignEnabled = true
            
            // ProGuard configuration
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Resource shrinking configuration
            resValue("string", "app_name", "Classes")
            
            // Build config optimizations
            buildConfigField("boolean", "ENABLE_LOGGING", "false")
            buildConfigField("boolean", "ENABLE_DEBUG_FEATURES", "false")
        }
        getByName("profile") {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
            
            // Profile optimizations
            isCrunchPngs = true
            isZipAlignEnabled = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}

// APK size analysis task
tasks.register("analyzeApkSize") {
    dependsOn("assembleRelease")
    doLast {
        val apkFile = file("build/outputs/apk/release/app-release.apk")
        if (apkFile.exists()) {
            val sizeInBytes = apkFile.length()
            val sizeInMB = sizeInBytes / (1024 * 1024)
            println("APK Size: $sizeInMB MB ($sizeInBytes bytes)")
            
            // Analyze APK contents
            exec {
                commandLine("aapt", "dump", "badging", apkFile.absolutePath)
            }
        } else {
            println("APK file not found. Build the release APK first.")
        }
    }
}

// Clean and rebuild task for size optimization
tasks.register("cleanAndRebuild") {
    dependsOn("clean")
    dependsOn("assembleRelease")
    doLast {
        println("Clean rebuild completed. Check APK size for optimization results.")
    }
}

// Task to generate keystore if it doesn't exist
tasks.register("generateKeystore") {
    doLast {
        val keystoreFile = file("myclassteacher.keystore")
        if (!keystoreFile.exists()) {
            println("Generating keystore file...")
            exec {
                commandLine(
                    "keytool",
                    "-genkey",
                    "-v",
                    "-keystore", "myclassteacher.keystore",
                    "-alias", "myclassteacher",
                    "-keyalg", "RSA",
                    "-keysize", "2048",
                    "-validity", "10000",
                    "-storepass", project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as String? ?: "your_store_password",
                    "-keypass", project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as String? ?: "your_key_password",
                    "-dname", "CN=MyClassTeacher, OU=Development, O=FusionLKit, L=Colombo, S=Western, C=LK"
                )
            }
            println("Keystore generated successfully!")
        } else {
            println("Keystore already exists.")
        }
    }
}

// Task to build signed app bundle
tasks.register("buildSignedBundle") {
    dependsOn("generateKeystore")
    dependsOn("bundleRelease")
    doLast {
        println("Signed app bundle built successfully!")
        val bundleFile = file("build/outputs/bundle/release/app-release.aab")
        if (bundleFile.exists()) {
            val sizeInBytes = bundleFile.length()
            val sizeInMB = sizeInBytes / (1024 * 1024)
            println("App Bundle Size: $sizeInMB MB ($sizeInBytes bytes)")
            println("Bundle location: ${bundleFile.absolutePath}")
        }
    }
}

// Task to build signed APK
tasks.register("buildSignedApk") {
    dependsOn("generateKeystore")
    dependsOn("assembleRelease")
    doLast {
        println("Signed APK built successfully!")
        val apkFile = file("build/outputs/apk/release/app-release.apk")
        if (apkFile.exists()) {
            val sizeInBytes = apkFile.length()
            val sizeInMB = sizeInBytes / (1024 * 1024)
            println("APK Size: $sizeInMB MB ($sizeInBytes bytes)")
            println("APK location: ${apkFile.absolutePath}")
        }
    }
}
