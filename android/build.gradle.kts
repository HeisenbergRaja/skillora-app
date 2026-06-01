buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.4")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

subprojects {
    val forceCompileSdk = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Try AGP 8.0+ DSL
                val method = android.javaClass.getMethod("setCompileSdk", Integer::class.java)
                method.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    // Try older AGP DSL
                    val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(android, 36)
                } catch (e2: Exception) {
                    // Fallback to property if possible
                }
            }
        }
    }

    if (project.state.executed) {
        forceCompileSdk()
    } else {
        afterEvaluate {
            forceCompileSdk()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
