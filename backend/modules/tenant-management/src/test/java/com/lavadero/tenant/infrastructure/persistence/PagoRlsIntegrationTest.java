package com.lavadero.tenant.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.TenantManagementTestApplication;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.math.BigDecimal;
import java.time.Instant;
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
 * Calcado de {@link SucursalRlsIntegrationTest} para `pago` (V14). Además de listar, prueba {@code
 * findByReferencia}: es la búsqueda que hará el webhook de la pasarela, y una referencia de otro
 * tenant nunca debe resolverse.
 */
@SpringBootTest(classes = TenantManagementTestApplication.class)
@Testcontainers
class PagoRlsIntegrationTest {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);

    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private PagoRepository pagoRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unTenantNuncaVeLosPagosDeOtroTenant() {
    UUID tenantA = crearTenant("lavadero-a");
    UUID tenantB = crearTenant("lavadero-b");

    Pago pagoA = pagoDe(tenantA);
    Pago pagoB = pagoDe(tenantB);
    comoTenant(tenantA, () -> pagoRepository.save(pagoA));
    comoTenant(tenantB, () -> pagoRepository.save(pagoB));

    List<Pago> visiblesParaA =
        comoTenant(tenantA, () -> pagoRepository.findRecientesDelTenantActual(50));
    assertThat(visiblesParaA).extracting(Pago::getId).containsExactly(pagoA.getId());

    List<Pago> visiblesParaB =
        comoTenant(tenantB, () -> pagoRepository.findRecientesDelTenantActual(50));
    assertThat(visiblesParaB).extracting(Pago::getId).containsExactly(pagoB.getId());

    assertThat(comoTenant(tenantA, () -> pagoRepository.findByReferencia(pagoB.getReferencia())))
        .isEmpty();
    assertThat(comoTenant(tenantA, () -> pagoRepository.findByReferencia(pagoA.getReferencia())))
        .isPresent();
  }

  private static Pago pagoDe(UUID tenantId) {
    return Pago.nuevo(
        tenantId,
        PLAN_STARTER_ID,
        Money.cop(new BigDecimal("99000")),
        "ref-" + UUID.randomUUID(),
        Instant.now());
  }

  private UUID crearTenant(String prefijoSlug) {
    Tenant tenant =
        Tenant.nuevo(
            "Lavadero",
            "NIT-" + UUID.randomUUID(),
            prefijoSlug + "-" + UUID.randomUUID().toString().substring(0, 8),
            PLAN_STARTER_ID);
    tenantRepository.save(tenant);
    return tenant.getId();
  }

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
}
