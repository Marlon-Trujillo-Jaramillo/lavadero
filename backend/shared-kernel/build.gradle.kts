/*
 * Kernel compartido (com.lavadero.shared): tipos base de dominio,
 * excepciones de aplicación y utilidades de seguridad multi-tenant que
 * usan TODOS los módulos de negocio. No depende de ningún otro módulo
 * de negocio ni de Spring Web/JPA: solo de spring-context (para poder
 * anotar, si hace falta, componentes) y jakarta.validation.
 */

plugins {
    id("lavadero.module-conventions")
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter")
}
