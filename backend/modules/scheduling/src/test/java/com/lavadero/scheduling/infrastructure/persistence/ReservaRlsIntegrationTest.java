package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Instant;
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

/**
 * Calcado de {@code ServicioRlsIntegrationTest}/{@code SucursalRlsIntegrationTest}: prueba la
 * política RLS REAL (Testcontainers, sin mocks) de la tabla `reserva`, conectando con el rol
 * no-superusuario `lavadero_app`. Fixtures de otros módulos vía {@link RlsTestFixtures}.
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ReservaRlsIntegrationTest {

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

  @Autowired private ReservaRepository reservaRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;

  @Test
  void unTenantNuncaVeLaReservaDeOtroTenant() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);

    UUID tenantA = fixtures.crearTenant("Lavadero A");
    UUID sucursalA = fixtures.crearSucursal(tenantA);
    UUID servicioA = fixtures.crearServicio(tenantA, "Lavado básico");
    UUID clienteA = fixtures.crearUsuario(tenantA);

    UUID tenantB = fixtures.crearTenant("Lavadero B");
    UUID sucursalB = fixtures.crearSucursal(tenantB);
    UUID servicioB = fixtures.crearServicio(tenantB, "Lavado básico");
    UUID clienteB = fixtures.crearUsuario(tenantB);

    Instant inicio = Instant.parse("2026-08-01T10:00:00Z");
    Reserva reservaA =
        Reserva.nueva(
            tenantA,
            sucursalA,
            servicioA,
            clienteA,
            inicio,
            20,
            Money.cop(BigDecimal.valueOf(15000)));
    Reserva reservaB =
        Reserva.nueva(
            tenantB,
            sucursalB,
            servicioB,
            clienteB,
            inicio,
            20,
            Money.cop(BigDecimal.valueOf(18000)));

    fixtures.comoTenant(tenantA, () -> reservaRepository.save(reservaA));
    fixtures.comoTenant(tenantB, () -> reservaRepository.save(reservaB));

    List<Reserva> visiblesParaA =
        fixtures.comoTenant(
            tenantA,
            () ->
                reservaRepository.findPorSucursalYRango(
                    sucursalA, inicio.minusSeconds(3600), inicio.plusSeconds(3600)));
    assertThat(visiblesParaA).extracting(Reserva::getId).containsExactly(reservaA.getId());

    List<Reserva> visiblesParaB =
        fixtures.comoTenant(
            tenantB,
            () ->
                reservaRepository.findPorSucursalYRango(
                    sucursalB, inicio.minusSeconds(3600), inicio.plusSeconds(3600)));
    assertThat(visiblesParaB).extracting(Reserva::getId).containsExactly(reservaB.getId());
  }
}
