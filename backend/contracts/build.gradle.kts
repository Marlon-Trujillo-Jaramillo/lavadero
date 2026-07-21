/*
 * Eventos de dominio compartidos entre módulos (com.lavadero.contracts).
 * Solo depende de shared-kernel (para el contrato DomainEvent). Ningún
 * módulo de negocio debe exponer sus eventos "internos" aquí: solo los que
 * otro bounded context necesita consumir.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    api(project(":shared-kernel"))
}
