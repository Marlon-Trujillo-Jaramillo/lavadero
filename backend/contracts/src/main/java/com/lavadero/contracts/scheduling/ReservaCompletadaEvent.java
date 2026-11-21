package com.lavadero.contracts.scheduling;

import com.lavadero.contracts.EventoIntegracion;
import java.time.Instant;
import java.util.UUID;

/**
 * Publicado por `scheduling` cuando un empleado marca un lavado como terminado. `inventory` lo usa
 * para descontar los insumos de la receta del servicio, sin que `scheduling` sepa que existe un
 * inventario. Viaja por el outbox (ver docs/specs/013-eventos-kafka.md).
 */
public record ReservaCompletadaEvent(
    UUID reservaId, UUID tenantId, UUID sucursalId, UUID servicioId, Instant occurredOn)
    implements EventoIntegracion {

  /** Los eventos de una misma reserva van a la misma partición. */
  @Override
  public String clave() {
    return reservaId.toString();
  }
}
