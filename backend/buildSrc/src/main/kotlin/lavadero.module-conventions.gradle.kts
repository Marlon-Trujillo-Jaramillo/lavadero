/*
 * Convención para los módulos de negocio (bounded contexts) y para el
 * módulo ejecutable. Aplica java-conventions y añade:
 * - Gestión de versiones centralizada a través del módulo `platform`
 *   (java-platform / BOM), para que ningún build.gradle.kts de módulo
 *   tenga que fijar una versión de Spring Boot, Testcontainers, jjwt, etc.
 * - Dependencias comunes a cualquier módulo de negocio (Spring context,
 *   validation) que casi todos necesitan sin acoplarlos a web/persistence,
 *   que cada módulo decide explícitamente según lo necesite.
 */

plugins {
    id("lavadero.java-conventions")
    `java-library`
}

dependencies {
    "implementation"(platform(project(":platform")))
    "annotationProcessor"(platform(project(":platform")))
    "testImplementation"(platform(project(":platform")))

    // Casi todo módulo de dominio/aplicación necesita anotaciones de
    // inyección/validación estándar; no arrastra Spring Web ni JPA.
    "implementation"("org.springframework:spring-context")
    "implementation"("jakarta.validation:jakarta.validation-api")
}
