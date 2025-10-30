// android/build.gradle.kts

buildscript {
    // ✅ Define Kotlin version properly
    val kotlin_version = "1.8.0"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // ✅ Use the Kotlin Gradle plugin (required for Kotlin DSL)
        classpath("com.android.tools.build:gradle:8.2.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Configure unified build directory (optional but fine)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// ✅ Make sure app project is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean task definition
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
