// Configuración común a todos los módulos Android (plantilla de Flutter).

// De dónde se descargan las bibliotecas de Android de la app y de los complementos.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Lo compilado va a frontend/build/ (no a android/build/), que es donde Flutter lo busca.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Cada módulo (la app y cada complemento con código Android) en su propia subcarpeta.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Gradle configura primero la app y después los complementos, que dependen de ella.
subprojects {
    project.evaluationDependsOn(":app")
}

// «gradlew clean» borra todo lo compilado.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
