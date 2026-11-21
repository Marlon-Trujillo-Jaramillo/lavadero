package com.lavadero.messaging;

import com.lavadero.contracts.CatalogoEventos;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Publica lo pendiente del outbox. Cada pasada toma un lote con {@code FOR UPDATE SKIP LOCKED}:
 * varias instancias del backend pueden correr el relay a la vez sin publicar dos veces el mismo
 * evento (cada una salta las filas que otra ya tomó).
 *
 * <p>Un envío que falla no frena el lote: se anota el error y el próximo intento se aleja con
 * backoff exponencial (2, 4, 8 s ... hasta 5 min). La entrega es "al menos una vez": si Kafka
 * confirma pero la transacción del relay no llega a hacer commit, el evento se vuelve a enviar. Por
 * eso los manejadores son idempotentes.
 */
@Component
public class RelayOutbox {

  private static final Logger log = LoggerFactory.getLogger(RelayOutbox.class);
  static final int LOTE = 50;
  static final Duration BACKOFF_MAXIMO = Duration.ofMinutes(5);

  private final JdbcTemplate jdbc;
  private final TransactionTemplate tx;
  private final TransporteEventos transporte;
  private final Clock reloj;

  public RelayOutbox(
      JdbcTemplate jdbc,
      PlatformTransactionManager transactionManager,
      TransporteEventos transporte,
      Clock reloj) {
    this.jdbc = jdbc;
    this.tx = new TransactionTemplate(transactionManager);
    this.transporte = transporte;
    this.reloj = reloj;
  }

  @Scheduled(
      fixedDelayString = "${lavadero.mensajeria.relay-ms:1000}",
      initialDelayString = "${lavadero.mensajeria.relay-ms:1000}")
  public void programado() {
    try {
      publicarPendientes();
    } catch (RuntimeException e) {
      // Base de datos caída, p. ej.: se intenta en la próxima pasada.
      log.warn("El relay del outbox no pudo correr: {}", e.getMessage());
    }
  }

  /** Publica un lote y devuelve cuántos eventos salieron. */
  public int publicarPendientes() {
    Integer publicados = tx.execute(status -> publicarLote());
    return publicados == null ? 0 : publicados;
  }

  private int publicarLote() {
    // Sin tenant: el relay es del sistema (ver la política RLS de V25).
    jdbc.queryForObject("select set_config('app.current_tenant_id', '', true)", String.class);
    Instant ahora = reloj.instant();
    List<EntradaOutbox> pendientes =
        jdbc.query(
            "select id, tenant_id, tipo, clave, payload::text as payload, intentos"
                + " from outbox_evento"
                + " where publicado_en is null and proximo_intento <= ?"
                + " order by creado_en limit ? for update skip locked",
            (rs, n) -> {
              String tipo = rs.getString("tipo");
              return new EntradaOutbox(
                  rs.getObject("id", UUID.class),
                  rs.getObject("tenant_id", UUID.class),
                  tipo,
                  CatalogoEventos.porNombre(tipo).map(CatalogoEventos.Tipo::topico).orElse(null),
                  rs.getString("clave"),
                  rs.getString("payload"),
                  rs.getInt("intentos"));
            },
            Timestamp.from(ahora),
            LOTE);
    int publicados = 0;
    for (EntradaOutbox entrada : pendientes) {
      try {
        transporte.enviar(entrada);
        jdbc.update(
            "update outbox_evento set publicado_en = ?, intentos = intentos + 1,"
                + " ultimo_error = null where id = ?",
            Timestamp.from(reloj.instant()),
            entrada.id());
        publicados++;
      } catch (Exception e) {
        if (e instanceof InterruptedException) {
          Thread.currentThread().interrupt();
        }
        registrarFallo(entrada, e);
      }
    }
    return publicados;
  }

  private void registrarFallo(EntradaOutbox entrada, Exception e) {
    int intento = entrada.intentos() + 1;
    Duration espera = backoff(intento);
    String error = e.getClass().getSimpleName() + ": " + e.getMessage();
    log.warn(
        "Evento {} ({}) no se pudo publicar, intento {}; reintento en {}s: {}",
        entrada.id(),
        entrada.tipo(),
        intento,
        espera.toSeconds(),
        error);
    jdbc.update(
        "update outbox_evento set intentos = ?, proximo_intento = ?, ultimo_error = ? where id = ?",
        intento,
        Timestamp.from(reloj.instant().plus(espera)),
        error.length() > 500 ? error.substring(0, 500) : error,
        entrada.id());
  }

  static Duration backoff(int intento) {
    long segundos = 1L << Math.min(intento, 20);
    Duration espera = Duration.ofSeconds(segundos);
    return espera.compareTo(BACKOFF_MAXIMO) > 0 ? BACKOFF_MAXIMO : espera;
  }
}
