/*
 * Bounded context: inventario de insumos (com.lavadero.inventory). Conoce Sucursal y Servicio solo
 * por id (FK en el esquema, casos de uso de `catalog` para leer precios). No depende de
 * `scheduling`: reacciona a `ReservaCompletadaEvent`, que vive en `contracts`.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    implementation(project(":contracts"))
    implementation(project(":modules:catalog"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    // Migraciones de las tablas a las que apuntan las FK (tenant, sucursal, servicio).
    testRuntimeOnly(project(":modules:tenant-management"))
}
