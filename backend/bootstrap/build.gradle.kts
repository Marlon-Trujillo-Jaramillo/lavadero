/*
 * Módulo ejecutable (Spring Boot). Ensambla todos los bounded contexts de
 * negocio en un único proceso desplegable (Modular Monolith): depende de
 * TODOS los módulos de negocio; ningún módulo de negocio depende de
 * `bootstrap` (evitaría ciclos y rompería la independencia entre bounded
 * contexts salvo las dependencias explícitas ya declaradas en sus propios
 * build.gradle.kts, p. ej. identity-access -> tenant-management).
 */

plugins {
    id("lavadero.module-conventions")
    // Sin versión explícita: el plugin ya llega al classpath del build vía
    // la dependencia declarada en `buildSrc/build.gradle.kts`
    // (spring-boot-gradle-plugin), la misma fuente de verdad de versión
    // que usan los demás módulos a través de `platform`.
    id("org.springframework.boot")
}

dependencies {
    implementation(project(":modules:tenant-management"))
    implementation(project(":modules:identity-access"))
    implementation(project(":modules:catalog"))
    implementation(project(":modules:scheduling"))

    implementation("org.springframework.boot:spring-boot-starter-actuator")
    // Necesario aquí (no solo transitivamente vía los módulos de negocio,
    // que lo declaran como `implementation` y por tanto no lo exponen) para
    // que `GlobalExceptionHandler` (@RestControllerAdvice) compile.
    implementation("org.springframework.boot:spring-boot-starter-web")
    // Ídem: `@EnableJpaRepositories`/`@EntityScan` en Application.java (ver
    // su Javadoc) necesitan estas clases en el classpath de compilación de
    // este módulo, no solo transitivamente.
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")

    // Monitoreo de errores (ver docs/specs/004-observabilidad.md). Solo en
    // `bootstrap` (el DSN es de todo el proceso, no de cada módulo). Si
    // `sentry.dsn` está vacío (por defecto, sin cuenta de Sentry creada
    // todavía) el SDK no envía nada — arranque/tests no dependen de tener
    // una cuenta real.
    val sentryVersion: String by project
    implementation("io.sentry:sentry-spring-boot-starter-jakarta:$sentryVersion")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
}

tasks.named<Jar>("jar") {
    enabled = false
}
