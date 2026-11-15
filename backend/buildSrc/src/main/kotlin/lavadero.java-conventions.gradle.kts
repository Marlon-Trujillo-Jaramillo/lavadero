import com.diffplug.gradle.spotless.SpotlessExtension

/*
 * Convención base de Java para TODOS los subproyectos del monolito modular.
 * - Java 21 (LTS) como toolchain.
 * - Spotless para formateo consistente (google-java-format).
 * - JUnit 5 + AssertJ como stack de test por defecto.
 * - Testcontainers disponible en testImplementation para quien lo necesite
 *   (no todos los módulos lo usan, pero se deja centralizado aquí para
 *   evitar declarar la versión en cada build.gradle.kts).
 */

plugins {
    java
    jacoco
    id("com.diffplug.spotless")
}

// Cobertura de tests: cada `test` genera su reporte XML (lo lee el CI para
// publicar el porcentaje en el resumen del run) y HTML (para revisar en local
// en build/reports/jacoco/test/html/index.html).
tasks.named<JacocoReport>("jacocoTestReport") {
    dependsOn(tasks.named("test"))
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
}

tasks.named("test") {
    finalizedBy(tasks.named("jacocoTestReport"))
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

repositories {
    mavenCentral()
}

configure<SpotlessExtension> {
    java {
        googleJavaFormat("1.22.0")
        target("src/*/java/**/*.java")
        removeUnusedImports()
        trimTrailingWhitespace()
        endWithNewline()
    }
}

dependencies {
    "testImplementation"("org.junit.jupiter:junit-jupiter:5.11.3")
    "testImplementation"("org.assertj:assertj-core:3.26.3")
    "testImplementation"("org.mockito:mockito-core:5.14.2")
    "testImplementation"("org.mockito:mockito-junit-jupiter:5.14.2")
    "testRuntimeOnly"("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
    useJUnitPlatform()
    testLogging {
        events("passed", "skipped", "failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }

    // Docker en macOS a menudo corre vía Colima/Podman en vez de Docker
    // Desktop, con el socket en una ruta no estándar expuesta solo por
    // DOCKER_HOST. Gradle debería heredar el entorno del proceso que lanza
    // el build, pero en la práctica no siempre llega al JVM de test workers
    // reusados, así que se reenvía explícitamente para que Testcontainers
    // (usado por los tests de RLS) lo encuentre.
    listOf(
        "DOCKER_HOST",
        "TESTCONTAINERS_HOST_OVERRIDE",
        "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE",
    ).forEach { name -> System.getenv(name)?.let { environment(name, it) } }

    // docker-java (vendorizado dentro de Testcontainers) solo permite fijar
    // la versión de API Docker vía la system property "api.version" — no
    // lee ninguna variable de entorno para esto (su loop de overrides solo
    // acepta claves que matcheen exactamente CONFIG_KEYS, y "api.version"
    // con punto no es un nombre válido de env var). Motores Docker nuevos
    // (p. ej. el que trae Colima) rechazan la versión mínima que docker-java
    // usa por defecto (1.32) con "client version too old", así que se
    // reenvía explícitamente desde DOCKER_API_VERSION si el desarrollador la
    // define en su entorno.
    System.getenv("DOCKER_API_VERSION")?.let { systemProperty("api.version", it) }
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.compilerArgs.addAll(listOf("-parameters"))
}
