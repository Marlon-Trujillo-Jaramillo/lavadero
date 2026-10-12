package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.ChecklistItem;
import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** Calcado de {@code ReservaRlsIntegrationTest} para la tabla `checklist_item` (V16). */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ChecklistItemRlsIntegrationTest {

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

  @Autowired private ChecklistItemRepository checklistItemRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;

  @Test
  void unTenantNuncaVeElChecklistDeOtroTenant() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);

    UUID tenantA = fixtures.crearTenant("Lavadero A");
    UUID sucursalA = fixtures.crearSucursal(tenantA);
    UUID servicioA = fixtures.crearServicio(tenantA, "Lavado básico");
    UUID clienteA = fixtures.crearUsuario(tenantA);
    UUID reservaA = fixtures.crearReserva(tenantA, sucursalA, servicioA, clienteA);

    UUID tenantB = fixtures.crearTenant("Lavadero B");
    UUID sucursalB = fixtures.crearSucursal(tenantB);
    UUID servicioB = fixtures.crearServicio(tenantB, "Lavado básico");
    UUID clienteB = fixtures.crearUsuario(tenantB);
    UUID reservaB = fixtures.crearReserva(tenantB, sucursalB, servicioB, clienteB);

    ChecklistItem itemA = ChecklistItem.nuevo(tenantA, reservaA, ChecklistItemTipo.EXTERIOR_LAVADO);
    itemA.marcar(true);
    ChecklistItem itemB = ChecklistItem.nuevo(tenantB, reservaB, ChecklistItemTipo.EXTERIOR_LAVADO);

    fixtures.comoTenant(tenantA, () -> checklistItemRepository.save(itemA));
    fixtures.comoTenant(tenantB, () -> checklistItemRepository.save(itemB));

    List<ChecklistItem> visiblesParaA =
        fixtures.comoTenant(tenantA, () -> checklistItemRepository.findByReservaId(reservaA));
    assertThat(visiblesParaA).extracting(ChecklistItem::getId).containsExactly(itemA.getId());

    List<ChecklistItem> visiblesParaB =
        fixtures.comoTenant(tenantB, () -> checklistItemRepository.findByReservaId(reservaB));
    assertThat(visiblesParaB).extracting(ChecklistItem::getId).containsExactly(itemB.getId());
  }
}
