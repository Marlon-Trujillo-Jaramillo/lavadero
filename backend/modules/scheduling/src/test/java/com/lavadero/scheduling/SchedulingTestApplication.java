package com.lavadero.scheduling;

import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Aplicación Spring Boot mínima, solo para tests — mismo motivo que {@code
 * TenantManagementTestApplication}/{@code CatalogTestApplication}: {@code scheduling} es un módulo
 * librería, no aplica el plugin {@code org.springframework.boot}.
 *
 * <p>A diferencia de esas dos, este módulo SÍ depende de otros módulos de negocio
 * (tenant-management/catalog/identity-access) — su capa `application` usa casos de uso de esos
 * módulos, que no están disponibles como beans en este contexto de test aislado. El escaneo se
 * limita a `infrastructure.persistence` (lo único que {@code ReservaRlsIntegrationTest} necesita)
 * para no intentar instanciar esos casos de uso aquí.
 */
@SpringBootApplication(scanBasePackages = "com.lavadero.scheduling.infrastructure.persistence")
public class SchedulingTestApplication {}
