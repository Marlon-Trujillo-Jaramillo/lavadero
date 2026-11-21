package com.lavadero.pruebas.inventariokafka;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.lavadero.contracts.CatalogoEventos;
import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.model.UnidadMedida;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import com.lavadero.messaging.RelayOutbox;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.Currency;
import java.util.UUID;
import java.util.function.Supplier;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;

/**
 * De punta a punta contra Postgres y Kafka reales: una reserva completada (el evento publicado en
 * su transacción) termina descontando la receta del stock, pasando por outbox → relay → Kafka →
 * consumidor. Y si Kafka entrega el mismo mensaje dos veces, se descuenta una sola.
 */
@SpringBootTest(
    classes = InventoryKafkaTestApplication.class,
    properties = {
      "lavadero.mensajeria.transporte=kafka",
      "lavadero.mensajeria.relay.enabled=false",
      "spring.kafka.consumer.auto-offset-reset=earliest"
    })
@Testcontainers
class ConsumoPorKafkaIntegrationTest {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @Container static final KafkaContainer KAFKA = new KafkaContainer("apache/kafka-native:3.8.0");

  @DynamicPropertySource
  static void properties(DynamicPropertyRegistry registry) {
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");
    registry.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
  }

  @Autowired private RelayOutbox relay;
  @Autowired private ApplicationEventPublisher eventos;
  @Autowired private KafkaTemplate<String, String> kafka;
  @Autowired private InsumoRepository insumos;
  @Autowired private StockRepository stock;
  @Autowired private RecetaRepository recetas;
  @Autowired private MovimientoRepository movimientos;
  @Autowired private JdbcTemplate jdbc;
  @Autowired private PlatformTransactionManager transactionManager;

  private UUID tenant;
  private UUID sucursal;
  private UUID servicio;
  private Insumo shampoo;

  @BeforeEach
  void setUp() {
    tenant = UUID.randomUUID();
    sucursal = UUID.randomUUID();
    servicio = UUID.randomUUID();
    jdbc.update(
        "insert into tenant (id, nombre, nit, slug, estado, subscription_plan_id, fecha_creacion)"
            + " values (?, 'Lavadero', ?, ?, 'ACTIVO', ?, ?)",
        tenant,
        "NIT-" + tenant,
        "slug-" + tenant.toString().substring(0, 8),
        PLAN_STARTER_ID,
        Timestamp.from(Instant.now()));
    shampoo =
        Insumo.nuevo(
            tenant,
            "Shampoo",
            UnidadMedida.ML,
            new BigDecimal("12.5"),
            Currency.getInstance("COP"),
            Instant.now());
    comoTenant(
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
          insumos.save(shampoo);
          stock.sumar(tenant, shampoo.getId(), sucursal, new BigDecimal("100"));
          recetas.reemplazar(
              tenant,
              servicio,
              java.util.List.of(new LineaReceta(shampoo.getId(), new BigDecimal("40"))));
          return null;
        });
  }

  @Test
  void unaReservaCompletadaDescuentaLaRecetaPasandoPorKafka() {
    var evento =
        new ReservaCompletadaEvent(UUID.randomUUID(), tenant, sucursal, servicio, Instant.now());

    comoTenant(
        () -> {
          eventos.publishEvent(evento); // lo que hace CompletarReservaUseCase
          return null;
        });
    assertThat(relay.publicarPendientes()).isEqualTo(1);

    await()
        .atMost(Duration.ofSeconds(30))
        .until(() -> cantidad().compareTo(new BigDecimal("60")) == 0);
  }

  @Test
  void siKafkaEntregaElMismoMensajeDosVecesSeDescuentaUnaSola() throws Exception {
    var evento =
        new ReservaCompletadaEvent(UUID.randomUUID(), tenant, sucursal, servicio, Instant.now());
    comoTenant(
        () -> {
          eventos.publishEvent(evento);
          return null;
        });
    relay.publicarPendientes();
    await()
        .atMost(Duration.ofSeconds(30))
        .until(() -> cantidad().compareTo(new BigDecimal("60")) == 0);

    // Reentrega del mismo evento (p. ej. tras un rebalanceo del grupo de consumidores).
    String payload =
        jdbc.queryForObject(
            "select payload::text from outbox_evento where clave = ?",
            String.class,
            evento.reservaId().toString());
    var duplicado =
        new ProducerRecord<>(
            CatalogoEventos.RESERVA_COMPLETADA.topico(), evento.reservaId().toString(), payload);
    duplicado.headers().add("lavadero-tipo", "reserva.completada".getBytes(StandardCharsets.UTF_8));
    kafka.send(duplicado).get();

    await()
        .during(Duration.ofSeconds(3))
        .atMost(Duration.ofSeconds(10))
        .until(() -> cantidad().compareTo(new BigDecimal("60")) == 0);
    assertThat(comoTenant(() -> movimientos.recientes(shampoo.getId(), sucursal, 10))).hasSize(1);
  }

  private BigDecimal cantidad() {
    return comoTenant(() -> stock.deSucursal(sucursal)).stream()
        .filter(s -> s.insumoId().equals(shampoo.getId()))
        .findFirst()
        .orElseThrow()
        .cantidad();
  }

  private <T> T comoTenant(Supplier<T> accion) {
    return new TransactionTemplate(transactionManager)
        .execute(
            status -> {
              jdbc.queryForObject(
                  "select set_config('app.current_tenant_id', ?, true)",
                  String.class,
                  tenant.toString());
              return accion.get();
            });
  }
}
