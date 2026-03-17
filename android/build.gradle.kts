allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val flutterBuildDir = rootProject.file("../build")

subprojects {
    project.layout.buildDirectory.set(
        File("${flutterBuildDir}/${project.name}")
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(flutterBuildDir)
}
