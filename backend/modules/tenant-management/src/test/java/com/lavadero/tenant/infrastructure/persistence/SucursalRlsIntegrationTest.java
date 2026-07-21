package com.lavadero.tenant.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.tenant.TenantManagementTestApplication;
import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
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
 * Entregable de aceptación de la Fase 0: prueba la política Row Level Security REAL contra Postgres
 * (Testcontainers, sin mocks). Crea dos tenants (A y B) con una sucursal cada uno y verifica que,
 * situados en el contexto de tenant A, {@link SucursalRepository} NUNCA retorna la sucursal de B —
 * ni siquiera con {@code findAllDelTenantActual()}, que deliberadamente no añade ningún {@code
 * WHERE tenant_id = ...} manual (ver su Javadoc en {@code SucursalRepository}): toda la
 * responsabilidad de aislamiento recae en la política RLS de {@code V1__tenant_management.sql}.
 *
 * <p>Fija {@code app.current_tenant_id} directamente por SQL — {@code set_config(..., true)},
 * alcance de la transacción actual, equivalente parametrizado y seguro de {@code SET LOCAL}— en vez
 * de pasar por {@code TenantAwareTransactionAspect} (vive en el módulo `identity-access`, del que
 * `tenant-management` NO puede depender; ver comentario en su build.gradle.kts). Esto prueba la
 * barrera real (RLS de Postgres) de forma aislada, exactamente con el mismo mecanismo que usa ese
 * aspecto en producción, sin necesitar el módulo de identidad ni un JWT.
 */
@SpringBootTest(classes = TenantManagementTestApplication.class)
@Testcontainers
class SucursalRlsIntegrationTest {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    // Flyway corre las migraciones (CREATE TABLE/ROLE/POLICY) con el rol
    // admin por defecto de Testcontainers.
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);

    // El datasource de JPA/Hikari usado por los repositorios, en cambio,
    // debe conectar con el rol de aplicación NO-superusuario (creado por
    // V3__app_role.sql): si aquí se usara el rol admin, este test pasaría
    // aunque RLS estuviera completamente bypaseado, porque Postgres nunca
    // aplica RLS a un superusuario — exactamente el bug que este test
    // existe para atrapar.
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private SucursalRepository sucursalRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unTenantNuncaVeLaSucursalDeOtroTenant() {
    Tenant tenantA =
        Tenant.nuevo(
            "Lavadero A", "NIT-A-" + UUID.randomUUID(), slugUnico("lavadero-a"), PLAN_STARTER_ID);
    Tenant tenantB =
        Tenant.nuevo(
            "Lavadero B", "NIT-B-" + UUID.randomUUID(), slugUnico("lavadero-b"), PLAN_STARTER_ID);
    tenantRepository.save(tenantA);
    tenantRepository.save(tenantB);

    Sucursal sucursalA = Sucursal.principal(tenantA.getId());
    Sucursal sucursalB = Sucursal.principal(tenantB.getId());

    // Cada sucursal se crea bajo el contexto de SU PROPIO tenant, como
    // ocurriría en el onboarding real (CrearTenantUseCase).
    comoTenant(tenantA.getId(), () -> sucursalRepository.save(sucursalA));
    comoTenant(tenantB.getId(), () -> sucursalRepository.save(sucursalB));

    // Situados en el contexto de tenant A: la sucursal de B NUNCA debe
    // aparecer, sin importar que la query no tenga WHERE explícito.
    List<Sucursal> visiblesParaA =
        comoTenant(tenantA.getId(), () -> sucursalRepository.findAllDelTenantActual());

    assertThat(visiblesParaA).extracting(Sucursal::getId).containsExactly(sucursalA.getId());
    assertThat(visiblesParaA).extracting(Sucursal::getId).doesNotContain(sucursalB.getId());

    // Simétricamente, desde el contexto de B nunca se ve la de A.
    List<Sucursal> visiblesParaB =
        comoTenant(tenantB.getId(), () -> sucursalRepository.findAllDelTenantActual());
    assertThat(visiblesParaB).extracting(Sucursal::getId).containsExactly(sucursalB.getId());
  }

  /**
   * Replica exactamente el mecanismo de {@code TenantAwareTransactionAspect} (identity-access, no
   * disponible aquí): fija {@code app.current_tenant_id} con alcance de LA TRANSACCIÓN actual y
   * ejecuta la acción dentro de esa misma transacción/conexión. Al abrir una transacción nueva por
   * invocación, el valor fijado no se filtra entre llamadas ni queda visible fuera de ellas.
   */
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

  private static String slugUnico(String prefijo) {
    return prefijo + "-" + UUID.randomUUID().toString().substring(0, 8);
  }
}
