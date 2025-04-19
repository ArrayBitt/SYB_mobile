import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = layout.buildDirectory.dir("../../build").get()
layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.set(newSubprojectBuildDir)

    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(layout.buildDirectory)
}
