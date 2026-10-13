package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Duration;
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

/** {@code findPorCliente}: más recientes primero, con límite y cota inferior opcional. */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class MisReservasPaginacionIntegrationTest {

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

  @Test
  void devuelveLasMasRecientesPrimeroRespetandoLimiteYDesde() {
    var fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);
    UUID tenant = fixtures.crearTenant("Lavadero A");
    UUID sucursal = fixtures.crearSucursal(tenant);
    UUID servicio = fixtures.crearServicio(tenant, "Lavado básico");
    UUID cliente = fixtures.crearUsuario(tenant);
    Instant base = Instant.parse("2026-08-01T10:00:00Z");

    for (int dia = 0; dia < 4; dia++) {
      Reserva reserva =
          new Reserva(
              UUID.randomUUID(),
              tenant,
              sucursal,
              servicio,
              cliente,
              base.plus(Duration.ofDays(dia)),
              20,
              Money.cop(BigDecimal.valueOf(15000)),
              ReservaEstado.PENDIENTE);
      fixtures.comoTenant(tenant, () -> reservaRepository.save(reserva));
    }

    List<Instant> ultimasDos =
        fixtures
            .comoTenant(tenant, () -> reservaRepository.findPorCliente(cliente, null, 2))
            .stream()
            .map(Reserva::getFechaHoraInicio)
            .toList();
    assertThat(ultimasDos)
        .containsExactly(base.plus(Duration.ofDays(3)), base.plus(Duration.ofDays(2)));

    List<Reserva> desdeElDiaDos =
        fixtures.comoTenant(
            tenant,
            () -> reservaRepository.findPorCliente(cliente, base.plus(Duration.ofDays(2)), 50));
    assertThat(desdeElDiaDos).hasSize(2);
  }
}
