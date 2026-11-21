package com.lavadero.contracts.scheduling;

import com.lavadero.shared.domain.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Publicado por `scheduling` cuando un empleado marca un lavado como terminado. `inventory` lo usa
 * para descontar los insumos de la receta del servicio, sin que `scheduling` sepa que existe un
 * inventario. Hoy se entrega en el mismo proceso y la misma transacción; la fase de Kafka lo
 * llevará a un outbox (ver docs/specs/012-inventario.md).
 */
public record ReservaCompletadaEvent(
    UUID reservaId, UUID tenantId, UUID sucursalId, UUID servicioId, Instant occurredOn)
    implements DomainEvent {}
