import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// Workaround: ar_flutter_plugin não declara namespace (AGP 8+) e usa JVM target incompatível
subprojects {
    if (project.name == "ar_flutter_plugin") {
        project.plugins.withId("com.android.library") {
            project.extensions.getByType(LibraryExtension::class.java).apply {
                namespace = "io.carius.lars.ar_flutter_plugin"
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        project.tasks.withType(KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(flutterBuildDir)
}
