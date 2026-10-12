package com.lavadero.identity;

import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Aplicación Spring Boot mínima, solo para tests: {@code identity-access} es un módulo librería (no
 * ejecutable), pero {@code @SpringBootTest} necesita una clase de configuración raíz para levantar
 * un {@code ApplicationContext} (autoconfiguración de JPA, Flyway, DataSource) en los tests de
 * integración con Testcontainers.
 *
 * <p>Mismo motivo que {@code SchedulingTestApplication}: este módulo depende de
 * `tenant-management`, y su capa `application` (p. ej. {@code LoginUseCase}) usa casos de uso de
 * ese módulo que no están disponibles como beans en un contexto de test aislado. El escaneo se
 * limita a los repositorios JPA (lo único que los tests de RLS de este módulo necesitan) de ambos
 * módulos, sin arrastrar `application`/`interfaces`/`security`.
 *
 * <p>{@code @EnableJpaRepositories}/{@code @EntityScan} explícitos son necesarios ADEMÁS de {@code
 * scanBasePackages} — mismo motivo documentado en {@code bootstrap.Application}: Spring Data JPA se
 * rige por {@code AutoConfigurationPackages} (el paquete de esta clase, `com.lavadero.identity`),
 * no por el `scanBasePackages` de arriba, así que sin esto {@code TenantJpaRepository}
 * (tenant-management) nunca se registra como bean.
 */
@SpringBootApplication(
    scanBasePackages = {
      "com.lavadero.identity.infrastructure.persistence",
      "com.lavadero.tenant.infrastructure.persistence"
    })
@EnableJpaRepositories(
    basePackages = {
      "com.lavadero.identity.infrastructure.persistence",
      "com.lavadero.tenant.infrastructure.persistence"
    })
@EntityScan(
    basePackages = {
      "com.lavadero.identity.infrastructure.persistence",
      "com.lavadero.tenant.infrastructure.persistence"
    })
public class IdentityAccessTestApplication {}
