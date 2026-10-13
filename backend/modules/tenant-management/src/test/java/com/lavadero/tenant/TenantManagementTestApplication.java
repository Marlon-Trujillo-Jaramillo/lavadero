package com.lavadero.tenant;

import java.time.Clock;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * Aplicación Spring Boot mínima, solo para tests: {@code tenant-management} es un módulo librería
 * (no ejecutable; ver su {@code build.gradle.kts}, no aplica el plugin {@code
 * org.springframework.boot}), pero {@code @SpringBootTest} necesita una clase de configuración raíz
 * para levantar un {@code ApplicationContext} completo (autoconfiguración de JPA, Flyway,
 * DataSource) en los tests de integración con Testcontainers.
 *
 * <p>Declara su propio {@link Clock}: el de producción vive en {@code bootstrap} (cableado
 * transversal), que este módulo no ve.
 */
@SpringBootApplication
public class TenantManagementTestApplication {

  @Bean
  Clock reloj() {
    return Clock.systemUTC();
  }
}
