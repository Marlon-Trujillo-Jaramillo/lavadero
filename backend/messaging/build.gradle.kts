/*
 * Mensajería entre módulos: outbox transaccional, relay y transportes (Kafka o en el mismo
 * proceso). Es infraestructura compartida, como `contracts`: no conoce ningún módulo de negocio
 * (ArchUnit lo verifica) y los módulos solo implementan `ManejadorEvento` para recibir.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    api(project(":contracts"))

    implementation("org.springframework.boot:spring-boot-starter-jdbc")
    implementation("org.springframework.boot:spring-boot-starter-json")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.kafka:spring-kafka")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.kafka:spring-kafka-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    testImplementation("org.testcontainers:kafka")
    testImplementation("org.awaitility:awaitility")
    // Migración de `tenant` (FK del outbox).
    testRuntimeOnly(project(":modules:tenant-management"))
}
