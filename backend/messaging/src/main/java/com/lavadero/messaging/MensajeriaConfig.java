package com.lavadero.messaging;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Activa el relay programado ({@code lavadero.mensajeria.relay.enabled}, por defecto sí; los tests
 * lo apagan para llamarlo a mano) y expone {@code lavadero.outbox.pendientes} en /actuator/metrics:
 * si crece, algo no está saliendo.
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(
    name = "lavadero.mensajeria.relay.enabled",
    havingValue = "true",
    matchIfMissing = true)
class MensajeriaConfig {

  MensajeriaConfig(
      ObjectProvider<MeterRegistry> registro,
      JdbcTemplate jdbc,
      PlatformTransactionManager transactionManager) {
    TransactionTemplate tx = new TransactionTemplate(transactionManager);
    tx.setReadOnly(true);
    registro.ifAvailable(
        r ->
            Gauge.builder(
                    "lavadero.outbox.pendientes",
                    () ->
                        tx.execute(
                            status -> {
                              jdbc.queryForObject(
                                  "select set_config('app.current_tenant_id', '', true)",
                                  String.class);
                              return jdbc.queryForObject(
                                  "select count(*) from outbox_evento where publicado_en is null",
                                  Long.class);
                            }))
                .description("Eventos del outbox que aún no se publican")
                .register(r));
  }
}
