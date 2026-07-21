// Config raíz. Los plugins concretos (java, spring, etc.) se aplican vía
// los convention plugins de buildSrc en cada subproyecto, para evitar
// duplicar configuración y mantener el build declarativo por módulo.

allprojects {
    group = "com.lavadero"
    version = "0.1.0-SNAPSHOT"
}

tasks.register("printModules") {
    doLast {
        subprojects.forEach { println(" - ${it.path}") }
    }
}
