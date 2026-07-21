package com.lavadero.catalog.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.catalog.CatalogTestApplication;
import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Calcado de {@code SucursalRlsIntegrationTest} (tenant-management): prueba la política RLS REAL
 * (Testcontainers, sin mocks) de la tabla `servicio` contra Postgres, conectando con el rol no-
 * superusuario `lavadero_app` (ver V3__app_role.sql) para que RLS realmente se aplique.
 */
@SpringBootTest(classes = CatalogTestApplication.class)
@Testcontainers
class ServicioRlsIntegrationTest {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    // Flyway (crea tenant/subscription_plan de tenant-management + servicio
    // de este módulo, el rol lavadero_app, etc.) corre con el rol admin.
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);

    // El datasource de JPA/Hikari, en cambio, conecta como lavadero_app: si
    // aquí se usara el rol admin, este test pasaría aunque RLS estuviera
    // completamente bypaseado (ver rls_superuser_bypass_bug).
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");
  }

  @Autowired private ServicioRepository servicioRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unTenantNuncaVeElServicioDeOtroTenant() {
    UUID tenantA = crearTenantDePrueba("Lavadero A");
    UUID tenantB = crearTenantDePrueba("Lavadero B");

    Servicio servicioA =
        Servicio.nuevo(tenantA, "Lavado básico A", null, 20, Money.cop(BigDecimal.valueOf(15000)));
    Servicio servicioB =
        Servicio.nuevo(tenantB, "Lavado básico B", null, 20, Money.cop(BigDecimal.valueOf(18000)));

    comoTenant(tenantA, () -> servicioRepository.save(servicioA));
    comoTenant(tenantB, () -> servicioRepository.save(servicioB));

    List<Servicio> visiblesParaA =
        comoTenant(tenantA, () -> servicioRepository.findAllDelTenantActual());
    assertThat(visiblesParaA).extracting(Servicio::getId).containsExactly(servicioA.getId());

    List<Servicio> visiblesParaB =
        comoTenant(tenantB, () -> servicioRepository.findAllDelTenantActual());
    assertThat(visiblesParaB).extracting(Servicio::getId).containsExactly(servicioB.getId());
  }

  /** Igual a {@code SucursalRlsIntegrationTest.comoTenant} — ver su Javadoc. */
  private <T> T comoTenant(UUID tenantId, Supplier<T> accion) {
    TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
    return transactionTemplate.execute(
        status -> {
          jdbcTemplate.queryForObject(
              "SELECT set_config('app.current_tenant_id', ?, true)",
              String.class,
              tenantId.toString());
          return accion.get();
        });
  }

  /**
   * Inserta un tenant mínimo directamente por SQL (en vez de usar {@code TenantRepository}, del
   * módulo tenant-management: `catalog` no depende de él en producción, solo trae su migración al
   * classpath de test para la FK `servicio.tenant_id -> tenant.id` — ver build.gradle.kts).
   */
  private UUID crearTenantDePrueba(String nombre) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        "insert into tenant (id, nombre, nit, slug, estado, subscription_plan_id, fecha_creacion) "
            + "values (?, ?, ?, ?, 'ACTIVO', ?, now())",
        id,
        nombre,
        "NIT-" + UUID.randomUUID(),
        "slug-" + UUID.randomUUID().toString().substring(0, 8),
        PLAN_STARTER_ID);
    return id;
  }
}
