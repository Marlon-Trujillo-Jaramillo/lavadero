package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.Incidencia;
import com.lavadero.scheduling.domain.model.IncidenciaCategoria;
import com.lavadero.scheduling.domain.repository.IncidenciaRepository;
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

/** Calcado de {@code ReservaRlsIntegrationTest} para la tabla `incidencia` (V17). */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class IncidenciaRlsIntegrationTest {

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

  @Autowired private IncidenciaRepository incidenciaRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;

  @Test
  void unTenantNuncaVeLaIncidenciaDeOtroTenant() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);

    UUID tenantA = fixtures.crearTenant("Lavadero A");
    UUID sucursalA = fixtures.crearSucursal(tenantA);
    UUID empleadoA = fixtures.crearUsuario(tenantA);

    UUID tenantB = fixtures.crearTenant("Lavadero B");
    UUID sucursalB = fixtures.crearSucursal(tenantB);
    UUID empleadoB = fixtures.crearUsuario(tenantB);

    Incidencia incidenciaA =
        Incidencia.nueva(
            tenantA,
            sucursalA,
            null,
            empleadoA,
            IncidenciaCategoria.FALTANTE_INSUMO,
            "Falta shampoo");
    Incidencia incidenciaB =
        Incidencia.nueva(
            tenantB, sucursalB, null, empleadoB, IncidenciaCategoria.FALTANTE_INSUMO, "Falta cera");

    fixtures.comoTenant(tenantA, () -> incidenciaRepository.save(incidenciaA));
    fixtures.comoTenant(tenantB, () -> incidenciaRepository.save(incidenciaB));

    List<Incidencia> visiblesParaA =
        fixtures.comoTenant(
            tenantA, () -> incidenciaRepository.findByReportadoPorUsuarioId(empleadoA));
    assertThat(visiblesParaA).extracting(Incidencia::getId).containsExactly(incidenciaA.getId());

    List<Incidencia> visiblesParaB =
        fixtures.comoTenant(
            tenantB, () -> incidenciaRepository.findByReportadoPorUsuarioId(empleadoB));
    assertThat(visiblesParaB).extracting(Incidencia::getId).containsExactly(incidenciaB.getId());
  }
}
