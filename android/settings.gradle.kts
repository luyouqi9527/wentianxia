// 3.0.0：从 Groovy DSL（AGP 8.6 / Gradle 8.7）迁移到 Flutter 3.47.5 官方模板基线：
//   Gradle 9.3.1 + AGP 9.1.0 + Kotlin 2.4.0（Kotlin DSL）
// 原因：Flutter 3.47.5 的 flutter-gradle-plugin 要求 Gradle ≥ 8.14 / AGP ≥ 8.9，
// 且 AGP 9 只读取新 DSL（模板通过 gradle.properties 的 android.newDsl=false 显式 opt out）。
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val path = properties.getProperty("flutter.sdk")
            require(path != null) { "flutter.sdk not set in local.properties" }
            path
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
