package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Instant;
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
 * Verifica que {@code ReservaRepository.obtenerResumenVentas} solo agrega reservas COMPLETADA (una
 * CANCELADA con el mismo rango de fechas no debe contar) y que el ranking de servicios más pedidos
 * refleja el conteo real.
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ReporteVentasIntegrationTest {

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
  void soloAgregaReservasCompletadasYRankeaLosServiciosMasPedidos() {
    var fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);

    UUID tenant = fixtures.crearTenant("Lavadero A");
    UUID sucursal = fixtures.crearSucursal(tenant);
    UUID servicioBasico = fixtures.crearServicio(tenant, "Lavado básico");
    UUID servicioPremium = fixtures.crearServicio(tenant, "Lavado premium");
    UUID cliente = fixtures.crearUsuario(tenant);

    Instant hoy = Instant.parse("2026-08-01T10:00:00Z");

    // Dos completadas de "Lavado básico" (15000 c/u) + una de "Lavado premium" (20000): total
    // esperado 50000, 3 reservas, "Lavado básico" primero en el ranking (cantidad 2).
    guardarCompletada(fixtures, tenant, sucursal, servicioBasico, cliente, hoy, 15000);
    guardarCompletada(fixtures, tenant, sucursal, servicioBasico, cliente, hoy, 15000);
    guardarCompletada(fixtures, tenant, sucursal, servicioPremium, cliente, hoy, 20000);

    // Una CANCELADA, mismo rango, NO debe contar.
    Reserva cancelada =
        new Reserva(
            UUID.randomUUID(),
            tenant,
            sucursal,
            servicioPremium,
            cliente,
            hoy,
            20,
            Money.cop(BigDecimal.valueOf(99999)),
            ReservaEstado.CANCELADA);
    fixtures.comoTenant(tenant, () -> reservaRepository.save(cancelada));

    ResumenVentas resumen =
        fixtures.comoTenant(
            tenant,
            () ->
                reservaRepository.obtenerResumenVentas(
                    hoy.minusSeconds(3600), hoy.plusSeconds(3600)));

    assertThat(resumen.ingresosTotales().monto()).isEqualByComparingTo("50000.00");
    assertThat(resumen.totalReservasCompletadas()).isEqualTo(3);
    assertThat(resumen.serviciosMasPedidos()).hasSize(2);
    assertThat(resumen.serviciosMasPedidos().get(0).servicioId()).isEqualTo(servicioBasico);
    assertThat(resumen.serviciosMasPedidos().get(0).cantidad()).isEqualTo(2);
  }

  private void guardarCompletada(
      RlsTestFixtures fixtures,
      UUID tenant,
      UUID sucursal,
      UUID servicio,
      UUID cliente,
      Instant fechaHoraInicio,
      long precio) {
    Reserva reserva =
        new Reserva(
            UUID.randomUUID(),
            tenant,
            sucursal,
            servicio,
            cliente,
            fechaHoraInicio,
            20,
            Money.cop(BigDecimal.valueOf(precio)),
            ReservaEstado.COMPLETADA);
    fixtures.comoTenant(tenant, () -> reservaRepository.save(reserva));
  }
}
