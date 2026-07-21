/*
 * Módulo BOM (java-platform). Centraliza el alineamiento de versiones de
 * todas las librerías usadas por más de un módulo del monolito, para que
 * cada build.gradle.kts de módulo solo declare `implementation("group:artifact")`
 * sin versión, y la versión real se resuelva vía `platform(project(":platform"))`.
 */

plugins {
    `java-platform`
}

javaPlatform {
    allowDependencies()
}

val springBootVersion: String by project
val testcontainersVersion: String by project
val archunitVersion: String by project
val jjwtVersion: String by project
val bucket4jVersion: String by project
val flywayVersion: String by project

dependencies {
    api(platform("org.springframework.boot:spring-boot-dependencies:$springBootVersion"))
    api(platform("org.testcontainers:testcontainers-bom:$testcontainersVersion"))

    constraints {
        api("com.tngtech.archunit:archunit-junit5:$archunitVersion")
        api("io.jsonwebtoken:jjwt-api:$jjwtVersion")
        api("io.jsonwebtoken:jjwt-impl:$jjwtVersion")
        api("io.jsonwebtoken:jjwt-jackson:$jjwtVersion")
        api("com.bucket4j:bucket4j-core:$bucket4jVersion")
        api("org.flywaydb:flyway-core:$flywayVersion")
        api("org.flywaydb:flyway-database-postgresql:$flywayVersion")
    }
}
