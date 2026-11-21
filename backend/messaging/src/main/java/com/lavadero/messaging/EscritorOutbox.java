package com.lavadero.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lavadero.contracts.CatalogoEventos;
import com.lavadero.contracts.EventoIntegracion;
import java.sql.Timestamp;
import java.time.Clock;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Guarda cada {@link EventoIntegracion} publicado con {@code ApplicationEventPublisher} en el
 * outbox, ANTES del commit de la transacción que lo publicó: el cambio de negocio y su evento se
 * confirman juntos o ninguno. Fuera de una transacción no se guarda nada (y eso es un error de
 * programación: publicar un evento de integración siempre ocurre dentro de un caso de uso).
 */
@Component
class EscritorOutbox {

  private final JdbcTemplate jdbc;
  private final ObjectMapper objectMapper;
  private final Clock reloj;

  EscritorOutbox(JdbcTemplate jdbc, ObjectMapper objectMapper, Clock reloj) {
    this.jdbc = jdbc;
    this.objectMapper = objectMapper;
    this.reloj = reloj;
  }

  @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
  void guardar(EventoIntegracion evento) {
    CatalogoEventos.Tipo tipo = CatalogoEventos.de(evento);
    Timestamp ahora = Timestamp.from(reloj.instant());
    jdbc.update(
        "insert into outbox_evento (id, tenant_id, tipo, clave, payload, creado_en, proximo_intento)"
            + " values (?, ?, ?, ?, cast(? as jsonb), ?, ?)",
        UUID.randomUUID(),
        evento.tenantId(),
        tipo.nombre(),
        evento.clave(),
        json(evento),
        ahora,
        ahora);
  }

  private String json(EventoIntegracion evento) {
    try {
      return objectMapper.writeValueAsString(evento);
    } catch (JsonProcessingException e) {
      throw new IllegalStateException(
          "No se pudo serializar " + evento.getClass().getSimpleName(), e);
    }
  }
}
