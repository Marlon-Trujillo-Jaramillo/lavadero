/*
 * Bounded context: catálogo de servicios y precios (com.lavadero.catalog).
 * Depende únicamente de shared-kernel y contracts — un Servicio solo
 * necesita tenantId (precio tenant-wide, sin variación por sucursal en
 * esta primera versión), así que no necesita tenant-management ni
 * identity-access como dependencia de compilación. El filtro de tenant a
 * nivel de Hibernate (TenantAwareTransactionAspect, en identity-access) se
 * activa igual en runtime porque `bootstrap` depende de ambos módulos —
 * ver ServicioJpaEntity.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    implementation(project(":contracts"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    // Solo de test: para que el classpath del test de RLS incluya la
    // migración V1 (tabla `tenant`/`subscription_plan`, de la que `servicio`
    // depende por FK) — el código de producción de `catalog` NO depende de
    // tenant-management (ver comentario arriba del archivo).
    testImplementation(project(":modules:tenant-management"))
}
