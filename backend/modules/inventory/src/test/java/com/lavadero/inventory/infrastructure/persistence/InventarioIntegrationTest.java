package com.lavadero.inventory.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.inventory.InventoryTestApplication;
import com.lavadero.inventory.application.usecase.RegistrarConsumoDeReservaUseCase;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.model.TipoMovimiento;
import com.lavadero.inventory.domain.model.UnidadMedida;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Currency;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Inventario contra Postgres real: sumas atómicas bajo concurrencia, conteo físico, consumo
 * idempotente al completar una reserva (por el evento, en la misma transacción) y RLS.
 */
@SpringBootTest(classes = InventoryTestApplication.class)
@Testcontainers
class InventarioIntegrationTest {

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

  @Autowired private InsumoRepository insumos;
  @Autowired private StockRepository stock;
  @Autowired private RecetaRepository recetas;
  @Autowired private MovimientoRepository movimientos;
  @Autowired private RegistrarConsumoDeReservaUseCase registrarConsumo;
  @Autowired private ApplicationEventPublisher eventos;
  @Autowired private JdbcTemplate jdbc;
  @Autowired private PlatformTransactionManager transactionManager;

  private UUID tenant;
  private UUID sucursal;
  private UUID servicio;
  private Insumo shampoo;

  @BeforeEach
  void setUp() {
    tenant = crearTenant();
    sucursal = UUID.randomUUID();
    servicio = UUID.randomUUID();
    comoTenant(
        tenant,
        () -> {
          jdbc.update(
              "insert into sucursal (id, tenant_id, nombre, capacidad_simultanea) values (?, ?, 'Sede', 1)",
              sucursal,
              tenant);
          jdbc.update(
              "insert into servicio (id, tenant_id, nombre, duracion_estimada_minutos, precio, moneda, activo)"
                  + " values (?, ?, 'Lavado', 30, 30000, 'COP', true)",
              servicio,
              tenant);
          return null;
        });
    shampoo = insumo(tenant, "Shampoo");
  }

  @Test
  void lasSumasSonAtomicasAunqueTerminenVariosLavadosALaVez() throws Exception {
    comoTenant(
        tenant, () -> stock.sumar(tenant, shampoo.getId(), sucursal, new BigDecimal("1000")));

    int lavados = 20;
    CountDownLatch salida = new CountDownLatch(1);
    ExecutorService hilos = Executors.newFixedThreadPool(lavados);
    try {
      List<Future<BigDecimal>> resultados = new ArrayList<>();
      for (int i = 0; i < lavados; i++) {
        resultados.add(
            hilos.submit(
                () -> {
                  salida.await();
                  return comoTenant(
                      tenant,
                      () -> stock.sumar(tenant, shampoo.getId(), sucursal, new BigDecimal("-40")));
                }));
      }
      salida.countDown();
      for (Future<BigDecimal> r : resultados) {
        r.get();
      }
    } finally {
      hilos.shutdownNow();
    }

    assertThat(cantidad()).isEqualByComparingTo("200"); // 1000 - 20 × 40
  }

  @Test
  void completarUnaReservaDescuentaLaRecetaUnaSolaVez() {
    comoTenant(tenant, () -> stock.sumar(tenant, shampoo.getId(), sucursal, new BigDecimal("100")));
    comoTenant(
        tenant,
        () -> {
          recetas.reemplazar(
              tenant, servicio, List.of(new LineaReceta(shampoo.getId(), new BigDecimal("40"))));
          return null;
        });
    var evento =
        new ReservaCompletadaEvent(UUID.randomUUID(), tenant, sucursal, servicio, Instant.now());

    assertThat(comoTenant(tenant, () -> registrarConsumo.execute(evento))).isEqualTo(1);
    assertThat(comoTenant(tenant, () -> registrarConsumo.execute(evento))).isZero();

    assertThat(cantidad()).isEqualByComparingTo("60");
    var kardex = comoTenant(tenant, () -> movimientos.recientes(shampoo.getId(), sucursal, 10));
    assertThat(kardex)
        .singleElement()
        .satisfies(
            m -> {
              assertThat(m.tipo()).isEqualTo(TipoMovimiento.CONSUMO);
              assertThat(m.saldo()).isEqualByComparingTo("60");
              assertThat(m.reservaId()).isEqualTo(evento.reservaId());
            });
  }

  @Test
  void elConsumoViajaConLaTransaccionQueCompletoLaReserva() {
    comoTenant(
        tenant,
        () -> {
          recetas.reemplazar(
              tenant, servicio, List.of(new LineaReceta(shampoo.getId(), new BigDecimal("40"))));
          return null;
        });
    var completada =
        new ReservaCompletadaEvent(UUID.randomUUID(), tenant, sucursal, servicio, Instant.now());
    var revertida =
        new ReservaCompletadaEvent(UUID.randomUUID(), tenant, sucursal, servicio, Instant.now());

    comoTenant(
        tenant,
        () -> {
          eventos.publishEvent(completada);
          return null;
        });
    TransactionTemplate tx = new TransactionTemplate(transactionManager);
    tx.executeWithoutResult(
        status -> {
          fijarTenant(tenant);
          eventos.publishEvent(revertida);
          status.setRollbackOnly(); // la reserva no llegó a completarse
        });

    // Solo el consumo de la transacción confirmada: el stock arranca en 0 y queda en -40.
    assertThat(cantidad()).isEqualByComparingTo("-40");
  }

  @Test
  void elConteoFisicoDevuelveLoQueHabiaYDejaLaDiferencia() {
    comoTenant(tenant, () -> stock.sumar(tenant, shampoo.getId(), sucursal, new BigDecimal("500")));

    BigDecimal anterior =
        comoTenant(
            tenant, () -> stock.fijar(tenant, shampoo.getId(), sucursal, new BigDecimal("430")));

    assertThat(anterior).isEqualByComparingTo("500");
    assertThat(cantidad()).isEqualByComparingTo("430");
  }

  @Test
  void unLavaderoNoVeLosInsumosNiElStockDeOtro() {
    UUID otro = crearTenant();
    insumo(otro, "Cera del otro");

    assertThat(comoTenant(tenant, () -> insumos.listarActivos()))
        .extracting(Insumo::getNombre)
        .containsExactly("Shampoo");
    assertThat(comoTenant(otro, () -> stock.deSucursal(sucursal))).isEmpty();
    assertThat(comoTenant(tenant, () -> insumos.existeActivoConNombre("shampoo"))).isTrue();
  }

  private BigDecimal cantidad() {
    return comoTenant(tenant, () -> stock.deSucursal(sucursal)).stream()
        .filter(s -> s.insumoId().equals(shampoo.getId()))
        .findFirst()
        .orElseThrow()
        .cantidad();
  }

  private Insumo insumo(UUID tenantId, String nombre) {
    Insumo nuevo =
        Insumo.nuevo(
            tenantId,
            nombre,
            UnidadMedida.ML,
            new BigDecimal("12.5"),
            Currency.getInstance("COP"),
            Instant.now());
    return comoTenant(tenantId, () -> insumos.save(nuevo));
  }

  private UUID crearTenant() {
    UUID id = UUID.randomUUID();
    jdbc.update(
        "insert into tenant (id, nombre, nit, slug, estado, subscription_plan_id, fecha_creacion)"
            + " values (?, 'Lavadero', ?, ?, 'ACTIVO', ?, ?)",
        id,
        "NIT-" + id,
        "slug-" + id.toString().substring(0, 8),
        PLAN_STARTER_ID,
        Timestamp.from(Instant.now()));
    return id;
  }

  private void fijarTenant(UUID tenantId) {
    jdbc.queryForObject(
        "select set_config('app.current_tenant_id', ?, true)", String.class, tenantId.toString());
  }

  private <T> T comoTenant(UUID tenantId, Supplier<T> accion) {
    return new TransactionTemplate(transactionManager)
        .execute(
            status -> {
              fijarTenant(tenantId);
              return accion.get();
            });
  }
}
