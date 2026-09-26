// 3.0.0：Kotlin DSL 版（Flutter 3.47.5 / Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0）。
//
// 签名策略（2.0.0 起）：仓库内固定一把密钥，debug 与 release 共用，
// 这样本机与 CodeMagic 产出的 APK 签名完全一致，覆盖安装不会再提示
// 「签名不一致，需要先卸载旧版本」。想换成自有密钥就把 jks 移出仓库，
// 改从 key.properties / 环境变量读取。
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreFile = file("wentianxia-release.jks")
val hasKeystore = keystoreFile.exists()

android {
    namespace = "com.wentianxia.news"
    // 3.0.0：插件（url_launcher_android / path_provider_android 等）要求 compileSdk ≥ 36，
    // 因此从 35 提到 36；targetSdk 保持 35（运行时行为不变，避免额外适配）。
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wentianxia.news"
        // url_launcher / hive_ce_flutter 需要 minSdk ≥ 21，这里取 23。
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasKeystore) {
            create("wentianxia") {
                storeFile = keystoreFile
                storePassword = "wentianxia2026"
                keyAlias = "wentianxia"
                keyPassword = "wentianxia2026"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("wentianxia")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            if (hasKeystore) {
                signingConfig = signingConfigs.getByName("wentianxia")
            }
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/NOTICE*",
            )
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
