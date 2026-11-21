package com.lavadero.messaging;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Outbox + relay con el transporte local, contra Postgres real: atomicidad con la transacción de
 * negocio, reintentos con backoff, RLS y que dos relays a la vez no entreguen dos veces.
 */
@SpringBootTest(
    classes = MessagingTestApplication.class,
    properties = {
      "lavadero.mensajeria.transporte=local",
      "lavadero.mensajeria.relay.enabled=false"
    })
@Testcontainers
class OutboxIntegrationTest {

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

  @Autowired private RelayOutbox relay;
  @Autowired private MessagingTestApplication.ManejadorDePrueba manejador;
  @Autowired private JdbcTemplate jdbc;
  @Autowired private PlatformTransactionManager transactionManager;
  @Autowired private ApplicationEventPublisher eventos;

  private OutboxFixtures fixtures;
  private UUID tenant;

  @BeforeEach
  void setUp() {
    fixtures = new OutboxFixtures(jdbc, transactionManager, eventos);
    tenant = fixtures.crearTenant();
    while (relay.publicarPendientes() > 0) {
      // vacía lo que dejaron otros tests
    }
    manejador.limpiar();
  }

  @Test
  void elEventoSeGuardaSoloSiLaTransaccionDeNegocioConfirma() {
    ReservaCompletadaEvent confirmado = OutboxFixtures.evento(tenant);
    ReservaCompletadaEvent revertido = OutboxFixtures.evento(tenant);

    fixtures.publicar(confirmado);
    fixtures.enTransaccion(
        tenant,
        status -> {
          eventos.publishEvent(revertido);
          status.setRollbackOnly(); // p. ej. la reserva no se pudo completar
        });

    assertThat(fixtures.contar(tenant, "publicado_en is null")).isEqualTo(1);
    assertThat(fixtures.contar(tenant, "clave = '" + confirmado.reservaId() + "'")).isEqualTo(1);
  }

  @Test
  void elRelayEntregaConElTenantDelEventoYNoRepite() {
    ReservaCompletadaEvent evento = OutboxFixtures.evento(tenant);
    fixtures.publicar(evento);

    assertThat(relay.publicarPendientes()).isEqualTo(1);
    assertThat(relay.publicarPendientes()).isZero();

    assertThat(manejador.recibidos)
        .singleElement()
        .satisfies(
            r -> {
              assertThat(r.evento()).isEqualTo(evento);
              assertThat(r.tenantEnContexto()).isEqualTo(tenant);
            });
    assertThat(fixtures.contar(tenant, "publicado_en is not null")).isEqualTo(1);
  }

  @Test
  void unManejadorQueFallaNoFrenaElLoteYSeReintentaConBackoff() {
    ReservaCompletadaEvent malo = OutboxFixtures.evento(tenant);
    ReservaCompletadaEvent bueno = OutboxFixtures.evento(tenant);
    manejador.reservasQueFallan.add(malo.reservaId());
    fixtures.publicar(malo);
    fixtures.publicar(bueno);

    assertThat(relay.publicarPendientes()).isEqualTo(1);

    assertThat(manejador.recibidos).extracting(r -> r.evento()).containsExactly(bueno);
    String condicion = "clave = '" + malo.reservaId() + "'";
    assertThat(fixtures.contar(tenant, condicion + " and publicado_en is null and intentos = 1"))
        .isEqualTo(1);
    assertThat(fixtures.contar(tenant, condicion + " and ultimo_error like '%Falla simulada%'"))
        .isEqualTo(1);
    // El próximo intento quedó en el futuro: una pasada inmediata no lo vuelve a tomar.
    assertThat(relay.publicarPendientes()).isZero();
    assertThat(RelayOutbox.backoff(1)).isEqualTo(Duration.ofSeconds(2));
    assertThat(RelayOutbox.backoff(30)).isEqualTo(RelayOutbox.BACKOFF_MAXIMO);
  }

  @Test
  void conTenantSoloSeVenSusEventosYElRelaySinTenantLosVeTodos() {
    UUID otro = fixtures.crearTenant();
    fixtures.publicar(OutboxFixtures.evento(tenant));
    fixtures.publicar(OutboxFixtures.evento(otro));

    assertThat(fixtures.contar(tenant, "publicado_en is null")).isEqualTo(1);
    assertThat(fixtures.contar(otro, "publicado_en is null")).isEqualTo(1);
    assertThat(fixtures.contar(null, "publicado_en is null")).isEqualTo(2);
  }

  @Test
  void dosRelaysALaVezNoEntreganDosVecesElMismoEvento() throws Exception {
    int total = 120;
    for (int i = 0; i < total; i++) {
      fixtures.publicar(OutboxFixtures.evento(tenant));
    }

    CountDownLatch salida = new CountDownLatch(1);
    ExecutorService hilos = Executors.newFixedThreadPool(3);
    try {
      List<Future<?>> relays = new ArrayList<>();
      for (int i = 0; i < 3; i++) {
        relays.add(
            hilos.submit(
                () -> {
                  salida.await();
                  while (relay.publicarPendientes() > 0) {
                    // sigue hasta vaciar
                  }
                  return null;
                }));
      }
      salida.countDown();
      for (Future<?> r : relays) {
        r.get();
      }
    } finally {
      hilos.shutdownNow();
    }

    var reservas = new HashSet<UUID>();
    manejador.recibidos.forEach(r -> reservas.add(r.evento().reservaId()));
    assertThat(manejador.recibidos).hasSize(total);
    assertThat(reservas).hasSize(total);
  }
}
