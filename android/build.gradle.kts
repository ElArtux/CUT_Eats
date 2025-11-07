
plugins {
    // 👇 Quita la versión para evitar conflicto
    id("com.google.gms.google-services") apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Asegúrate de tener las versiones correctas del Gradle plugin y Kotlin
        classpath("com.android.tools.build:gradle:8.6.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Configuración de directorios de build (mantén esto)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}