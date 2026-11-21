package com.lavadero.contracts;

import com.lavadero.shared.domain.DomainEvent;
import java.util.UUID;

/**
 * Un evento que cruza el límite del módulo que lo produce y viaja por el outbox (hoy a Kafka o
 * entregado en el mismo proceso, ver `messaging`). A diferencia de un {@link DomainEvent}
 * cualquiera, tiene que poder serializarse a JSON y llevar su tenant: quien lo consume no comparte
 * la petición HTTP ni el {@code TenantContext} de quien lo publicó.
 */
public interface EventoIntegracion extends DomainEvent {

  UUID tenantId();

  /**
   * Clave de partición en Kafka: los eventos con la misma clave llegan en orden (p. ej. todos los
   * de una misma reserva).
   */
  String clave();
}
