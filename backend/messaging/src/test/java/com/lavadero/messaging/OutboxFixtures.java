package com.lavadero.messaging;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import java.util.function.Consumer;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionTemplate;

/** Utilidades compartidas por los tests de mensajería. */
final class OutboxFixtures {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  private final JdbcTemplate jdbc;
  private final PlatformTransactionManager transactionManager;
  private final ApplicationEventPublisher eventos;

  OutboxFixtures(
      JdbcTemplate jdbc,
      PlatformTransactionManager transactionManager,
      ApplicationEventPublisher eventos) {
    this.jdbc = jdbc;
    this.transactionManager = transactionManager;
    this.eventos = eventos;
  }

  UUID crearTenant() {
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

  static ReservaCompletadaEvent evento(UUID tenant) {
    return new ReservaCompletadaEvent(
        UUID.randomUUID(), tenant, UUID.randomUUID(), UUID.randomUUID(), Instant.now());
  }

  /** Publica el evento dentro de una transacción "de negocio" del tenant, como un caso de uso. */
  void publicar(ReservaCompletadaEvent evento) {
    enTransaccion(evento.tenantId(), status -> eventos.publishEvent(evento));
  }

  void enTransaccion(UUID tenant, Consumer<TransactionStatus> accion) {
    new TransactionTemplate(transactionManager)
        .executeWithoutResult(
            status -> {
              jdbc.queryForObject(
                  "select set_config('app.current_tenant_id', ?, true)",
                  String.class,
                  tenant == null ? "" : tenant.toString());
              accion.accept(status);
            });
  }

  long contar(UUID tenant, String condicion) {
    Long[] total = new Long[1];
    enTransaccion(
        tenant,
        s ->
            total[0] =
                jdbc.queryForObject(
                    "select count(*) from outbox_evento where " + condicion, Long.class));
    return total[0];
  }
}
