/*
 * Bounded context: gestión de tenants (com.lavadero.tenant). Depende
 * únicamente de shared-kernel y contracts. NINGÚN otro módulo de negocio
 * puede ser dependencia de este (es el módulo "raíz" de negocio: todos los
 * demás dependerán de él, nunca al revés).
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
}
