package com.lavadero.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.lavadero.contracts.CatalogoEventos;
import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;
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
import org.testcontainers.kafka.KafkaContainer;

/**
 * El camino completo contra un Kafka real: outbox → relay → tópico (con clave y headers) →
 * consumidor → manejador con el tenant fijado; y un manejador que falla siempre termina en el
 * tópico {@code .DLT} sin frenar los demás mensajes.
 */
@SpringBootTest(
    classes = MessagingTestApplication.class,
    properties = {
      "lavadero.mensajeria.transporte=kafka",
      "lavadero.mensajeria.relay.enabled=false",
      "lavadero.mensajeria.kafka.reintentos=2",
      "spring.kafka.consumer.auto-offset-reset=earliest"
    })
@Testcontainers
class KafkaIntegrationTest {

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
    manejador.limpiar();
  }

  @Test
  void elEventoViajaPorKafkaConSuClaveYLlegaAlManejadorConSuTenant() {
    ReservaCompletadaEvent evento = OutboxFixtures.evento(tenant);
    fixtures.publicar(evento);

    assertThat(relay.publicarPendientes()).isEqualTo(1);

    await()
        .atMost(Duration.ofSeconds(30))
        .untilAsserted(
            () ->
                assertThat(manejador.recibidos)
                    .anySatisfy(
                        r -> {
                          assertThat(r.evento()).isEqualTo(evento);
                          assertThat(r.tenantEnContexto()).isEqualTo(tenant);
                        }));
    ConsumerRecord<String, String> mensaje =
        leerUno(CatalogoEventos.RESERVA_COMPLETADA.topico(), evento.reservaId().toString());
    assertThat(mensaje.key()).isEqualTo(evento.reservaId().toString());
    assertThat(header(mensaje, "lavadero-tipo")).isEqualTo("reserva.completada");
    assertThat(header(mensaje, "lavadero-tenant")).isEqualTo(tenant.toString());
  }

  @Test
  void unMensajeQueSiempreFallaTerminaEnLaColaDeMuertos() {
    ReservaCompletadaEvent malo = OutboxFixtures.evento(tenant);
    ReservaCompletadaEvent bueno = OutboxFixtures.evento(tenant);
    manejador.reservasQueFallan.add(malo.reservaId());
    fixtures.publicar(malo);
    fixtures.publicar(bueno);

    assertThat(relay.publicarPendientes()).isEqualTo(2);

    await()
        .atMost(Duration.ofSeconds(30))
        .untilAsserted(
            () -> assertThat(manejador.recibidos).anyMatch(r -> r.evento().equals(bueno)));
    ConsumerRecord<String, String> enDlt =
        leerUno(CatalogoEventos.RESERVA_COMPLETADA.topico() + ".DLT", malo.reservaId().toString());
    assertThat(header(enDlt, "kafka_dlt-exception-message")).contains("Falla simulada");
  }

  private static ConsumerRecord<String, String> leerUno(String topico, String clave) {
    Map<String, Object> config =
        Map.of(
            ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
            KAFKA.getBootstrapServers(),
            ConsumerConfig.GROUP_ID_CONFIG,
            "verificador-" + UUID.randomUUID(),
            ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,
            "earliest",
            ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
            StringDeserializer.class,
            ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
            StringDeserializer.class);
    try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(config)) {
      consumer.subscribe(List.of(topico));
      ConsumerRecord<String, String>[] encontrado = new ConsumerRecord[1];
      await()
          .atMost(Duration.ofSeconds(30))
          .until(
              () -> {
                for (ConsumerRecord<String, String> r : consumer.poll(Duration.ofMillis(500))) {
                  if (clave.equals(r.key())) {
                    encontrado[0] = r;
                  }
                }
                return encontrado[0] != null;
              });
      return encontrado[0];
    }
  }

  private static String header(ConsumerRecord<String, String> mensaje, String nombre) {
    var h = mensaje.headers().lastHeader(nombre);
    return h == null ? null : new String(h.value(), StandardCharsets.UTF_8);
  }
}
