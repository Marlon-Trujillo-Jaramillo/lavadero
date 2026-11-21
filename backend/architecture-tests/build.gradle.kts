/*
 * Tests de arquitectura (ArchUnit): verifica contra el bytecode REAL de
 * todos los módulos de negocio las reglas de Clean Architecture citadas
 * como comentarios de diseño en `shared-kernel` (p. ej. AggregateRoot,
 * UseCase) y en los build.gradle.kts de cada módulo (p. ej. "tenant-management
 * no puede depender de identity-access"). No produce ningún artefacto de
 * producción: solo código de test.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    testImplementation(project(":shared-kernel"))
    testImplementation(project(":contracts"))
    testImplementation(project(":modules:tenant-management"))
    testImplementation(project(":modules:identity-access"))
    testImplementation(project(":modules:catalog"))
    testImplementation(project(":modules:scheduling"))
    testImplementation(project(":modules:inventory"))
    testImplementation(project(":messaging"))

    testImplementation("com.tngtech.archunit:archunit-junit5")
}
