package com.lavadero.tenant;

import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Aplicación Spring Boot mínima, solo para tests: {@code tenant-management} es un módulo librería
 * (no ejecutable; ver su {@code build.gradle.kts}, no aplica el plugin {@code
 * org.springframework.boot}), pero {@code @SpringBootTest} necesita una clase de configuración raíz
 * para levantar un {@code ApplicationContext} completo (autoconfiguración de JPA, Flyway,
 * DataSource) en los tests de integración con Testcontainers.
 */
@SpringBootApplication
public class TenantManagementTestApplication {}
