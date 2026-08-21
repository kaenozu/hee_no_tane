import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties for release builds. The real file is ignored by Git.
val keystorePropsFile = rootProject.file("app/keystore.properties")
val keystoreProps = Properties()
if (keystorePropsFile.exists()) {
    keystorePropsFile.inputStream().use {
        keystoreProps.load(it)
    }
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val requiredSigningKeys = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val missingSigningKeys = requiredSigningKeys.filter {
    keystoreProps.getProperty(it).isNullOrBlank()
}
val releaseStoreFile = keystoreProps.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file("app/$it") }
val hasCompleteReleaseSigning =
    missingSigningKeys.isEmpty() && releaseStoreFile?.exists() == true

if (releaseTaskRequested) {
    if (!keystorePropsFile.exists()) {
        throw GradleException(
            "Release signing requires android/app/keystore.properties. " +
                "Copy keystore.properties.example and provide local secrets."
        )
    }
    if (missingSigningKeys.isNotEmpty()) {
        throw GradleException(
            "Release signing properties are missing: ${missingSigningKeys.joinToString()}."
        )
    }
    if (releaseStoreFile?.exists() != true) {
        throw GradleException(
            "Release keystore does not exist: ${releaseStoreFile?.path ?: "unknown"}."
        )
    }
}

android {
    namespace = "com.heenotane.hee_no_tane_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.heenotane.hee_no_tane_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Only release tasks receive the production AdMob App ID. All other
        // variants use Google's official test App ID.
        manifestPlaceholders["adMobAppId"] = if (releaseTaskRequested) {
            "ca-app-pub-1121980304554901~6127552891"
        } else {
            "ca-app-pub-3940256099942544~3347511713"
        }
    }

    signingConfigs {
        create("release") {
            if (hasCompleteReleaseSigning) {
                storeFile = releaseStoreFile
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (hasCompleteReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
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
