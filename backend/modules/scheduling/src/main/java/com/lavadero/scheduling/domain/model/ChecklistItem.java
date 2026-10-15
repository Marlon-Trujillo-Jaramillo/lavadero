package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Una tarea del checklist de servicio marcada (o desmarcada) para una {@link Reserva} concreta.
 * Puramente informativo: no bloquea ninguna transición de estado de la reserva (ver
 * docs/specs/006-checklist-incidencias.md) — evita acoplar dos conceptos que pueden evolucionar por
 * separado.
 */
public class ChecklistItem extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private final UUID reservaId;
  private final ChecklistItemTipo tipo;
  private boolean completado;
  private Instant completadoEn;

  public ChecklistItem(
      UUID id,
      UUID tenantId,
      UUID reservaId,
      ChecklistItemTipo tipo,
      boolean completado,
      Instant completadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.reservaId = Objects.requireNonNull(reservaId, "reservaId no puede ser nulo");
    this.tipo = Objects.requireNonNull(tipo, "tipo no puede ser nulo");
    this.completado = completado;
    this.completadoEn = completadoEn;
  }

  public static ChecklistItem nuevo(UUID tenantId, UUID reservaId, ChecklistItemTipo tipo) {
    return new ChecklistItem(UUID.randomUUID(), tenantId, reservaId, tipo, false, null);
  }

  public void marcar(boolean completado) {
    this.completado = completado;
    this.completadoEn = completado ? Instant.now() : null;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getReservaId() {
    return reservaId;
  }

  public ChecklistItemTipo getTipo() {
    return tipo;
  }

  public boolean isCompletado() {
    return completado;
  }

  public Instant getCompletadoEn() {
    return completadoEn;
  }
}
