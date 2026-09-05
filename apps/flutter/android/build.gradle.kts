allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Fix for libraries missing namespace (like isar_flutter_libs)
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension

            // Force compileSdkVersion to fix "resource android:attr/lStar not found"
            android.compileSdkVersion(35)

            if (android.namespace == null) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = groovy.xml.XmlParser().parse(manifestFile)
                    val packageName = manifest.attribute("package")?.toString()
                    if (packageName != null) {
                        android.namespace = packageName
                    } else {
                        // Fallback namespace if package is missing
                        android.namespace = "com.keihatsu.fallback.${project.name.replace(":", ".")}"
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
