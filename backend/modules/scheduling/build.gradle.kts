/*
 * Bounded context: agenda/reservas (com.lavadero.scheduling). A diferencia
 * de `catalog` (deliberadamente sin dependencias de negocio), este módulo
 * SÍ necesita conocer Sucursal (capacidad simultánea, tenant-management) y
 * Servicio (precio/duración a congelar en la reserva, catalog). El usuario
 * autenticado (PrincipalAutenticado) viene de shared-kernel, así que NO
 * depende de identity-access en producción: solo lo trae en tests, por sus
 * migraciones (reserva/incidencia tienen FK a usuario). Ninguno de esos
 * módulos depende de este.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    implementation(project(":contracts"))
    implementation(project(":modules:tenant-management"))
    implementation(project(":modules:catalog"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly(project(":modules:identity-access"))
    // Solo para que RlsPoliticasIntegrationTest revise también las migraciones de inventory.
    testRuntimeOnly(project(":modules:inventory"))
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
}
