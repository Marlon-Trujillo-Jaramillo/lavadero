/*
 * Bounded context: identidad y acceso (com.lavadero.identity). Depende de
 * shared-kernel y de tenant-management (para resolver el tenant en el
 * login por slug). NUNCA al revés: tenant-management no puede depender de
 * identity-access.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
    implementation(project(":contracts"))
    implementation(project(":modules:tenant-management"))

    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-aop")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    implementation("io.jsonwebtoken:jjwt-api")
    runtimeOnly("io.jsonwebtoken:jjwt-impl")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson")

    implementation("com.bucket4j:bucket4j-core")
    // Cache con eviction por inactividad para los buckets de RateLimitFilter:
    // un ConcurrentHashMap simple nunca libera entradas (una por IP+ruta,
    // para siempre). Versión gestionada por el BOM de Spring Boot (platform).
    implementation("com.github.ben-manes.caffeine:caffeine")

    // Argon2PasswordEncoder (PasswordEncoderConfig) lo necesita en runtime:
    // spring-security-crypto lo declara opcional, no lo trae por defecto.
    val bouncyCastleVersion: String by project
    runtimeOnly("org.bouncycastle:bcprov-jdk18on:$bouncyCastleVersion")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
}
