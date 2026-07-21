/*
 * Bounded context: agenda/reservas (com.lavadero.scheduling). A diferencia
 * de `catalog` (deliberadamente sin dependencias de negocio), este módulo
 * SÍ necesita conocer Sucursal (capacidad simultánea, tenant-management) y
 * Servicio (precio/duración a congelar en la reserva, catalog), y depende
 * de identity-access para leer el usuario autenticado actual
 * (JwtAuthenticatedPrincipal) en la capa `interfaces` — mismo patrón de
 * dependencia "hacia arriba" que ya usa identity-access con
 * tenant-management. Ninguno de esos tres módulos depende de este.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    implementation(project(":contracts"))
    implementation(project(":modules:tenant-management"))
    implementation(project(":modules:catalog"))
    implementation(project(":modules:identity-access"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
}
