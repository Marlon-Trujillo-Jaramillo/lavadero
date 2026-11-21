package com.lavadero.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lavadero.contracts.CatalogoEventos;
import com.lavadero.contracts.EventoIntegracion;
import com.lavadero.shared.security.TenantContext;
import java.util.List;
import org.springframework.stereotype.Component;

/**
 * Convierte un mensaje (nombre del tipo + JSON) en el evento y lo entrega a sus manejadores, con el
 * tenant del evento como contexto. Lo usan los dos transportes: así un manejador no sabe si el
 * evento vino de Kafka o del mismo proceso.
 */
@Component
public class DespachadorEventos {

  private final List<ManejadorEvento<?>> manejadores;
  private final ObjectMapper objectMapper;

  public DespachadorEventos(List<ManejadorEvento<?>> manejadores, ObjectMapper objectMapper) {
    this.manejadores = manejadores;
    this.objectMapper = objectMapper;
  }

  /** Lanza la excepción del manejador: el transporte decide si reintenta. */
  public void despachar(String nombreTipo, String payload) {
    CatalogoEventos.Tipo tipo =
        CatalogoEventos.porNombre(nombreTipo)
            .orElseThrow(
                () -> new IllegalArgumentException("Tipo de evento desconocido: " + nombreTipo));
    EventoIntegracion evento = leer(payload, tipo.clase());
    TenantContext.set(evento.tenantId());
    try {
      for (ManejadorEvento<?> manejador : manejadores) {
        if (manejador.tipo().equals(tipo.clase())) {
          entregar(manejador, evento);
        }
      }
    } finally {
      TenantContext.clear();
    }
  }

  @SuppressWarnings("unchecked")
  private static <E extends EventoIntegracion> void entregar(
      ManejadorEvento<E> manejador, EventoIntegracion evento) {
    manejador.manejar((E) evento);
  }

  private EventoIntegracion leer(String payload, Class<? extends EventoIntegracion> clase) {
    try {
      return objectMapper.readValue(payload, clase);
    } catch (JsonProcessingException e) {
      throw new IllegalArgumentException("Payload ilegible para " + clase.getSimpleName(), e);
    }
  }
}
