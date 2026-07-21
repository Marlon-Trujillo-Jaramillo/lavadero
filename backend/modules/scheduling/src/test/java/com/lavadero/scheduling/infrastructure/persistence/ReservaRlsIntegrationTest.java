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
 * Calcado de {@code ServicioRlsIntegrationTest}/{@code SucursalRlsIntegrationTest}: prueba la
 * política RLS REAL (Testcontainers, sin mocks) de la tabla `reserva`, conectando con el rol
 * no-superusuario `lavadero_app`. Los fixtures de tenant/sucursal/servicio/usuario (de otros
 * módulos, de los que `reserva` depende por FK) se insertan directo por SQL — igual que
 * `ServicioRlsIntegrationTest` hace con `tenant` — en vez de usar los repositorios de esos módulos,
 * que aquí no están disponibles como beans (este test solo levanta el contexto de `scheduling`).
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ReservaRlsIntegrationTest {

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

  @Autowired private ReservaRepository reservaRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unTenantNuncaVeLaReservaDeOtroTenant() {
    UUID tenantA = crearTenant("Lavadero A");
    UUID sucursalA = crearSucursal(tenantA);
    UUID servicioA = crearServicio(tenantA);
    UUID clienteA = crearUsuario(tenantA);

    UUID tenantB = crearTenant("Lavadero B");
    UUID sucursalB = crearSucursal(tenantB);
    UUID servicioB = crearServicio(tenantB);
    UUID clienteB = crearUsuario(tenantB);

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

    comoTenant(tenantA, () -> reservaRepository.save(reservaA));
    comoTenant(tenantB, () -> reservaRepository.save(reservaB));

    List<Reserva> visiblesParaA =
        comoTenant(
            tenantA,
            () ->
                reservaRepository.findPorSucursalYRango(
                    sucursalA, inicio.minusSeconds(3600), inicio.plusSeconds(3600)));
    assertThat(visiblesParaA).extracting(Reserva::getId).containsExactly(reservaA.getId());

    List<Reserva> visiblesParaB =
        comoTenant(
            tenantB,
            () ->
                reservaRepository.findPorSucursalYRango(
                    sucursalB, inicio.minusSeconds(3600), inicio.plusSeconds(3600)));
    assertThat(visiblesParaB).extracting(Reserva::getId).containsExactly(reservaB.getId());
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

  private UUID crearTenant(String nombre) {
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

  /**
   * A diferencia de `tenant` (sin RLS), `sucursal`/`servicio`/`usuario` SÍ tienen RLS+FORCE — el
   * insert debe correr con `app.current_tenant_id` ya fijado en la misma transacción, igual que
   * {@link #comoTenant}, o el rol `lavadero_app` lo rechaza.
   */
  private UUID crearSucursal(UUID tenantId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into sucursal (id, tenant_id, nombre, capacidad_simultanea) values (?, ?, 'Principal', 1)",
                id,
                tenantId));
    return id;
  }

  private UUID crearServicio(UUID tenantId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into servicio (id, tenant_id, nombre, duracion_estimada_minutos, precio, moneda, activo) "
                    + "values (?, ?, 'Lavado básico', 20, 15000, 'COP', true)",
                id,
                tenantId));
    return id;
  }

  private UUID crearUsuario(UUID tenantId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into usuario (id, tenant_id, email, nombre, password_hash, estado) "
                    + "values (?, ?, ?, 'Cliente de prueba', 'hash', 'ACTIVO')",
                id,
                tenantId,
                "cliente-" + UUID.randomUUID() + "@example.com"));
    return id;
  }
}
