package com.lavadero.scheduling.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/** El {@code @FilterDef} vive una sola vez en {@code SucursalJpaEntity}; aquí solo se referencia. */
@Entity
@Table(name = "checklist_item")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class ChecklistItemJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "reserva_id", nullable = false)
  private UUID reservaId;

  @Column(nullable = false)
  private String tipo;

  @Column(nullable = false)
  private boolean completado;

  @Column(name = "completado_en")
  private Instant completadoEn;

  protected ChecklistItemJpaEntity() {}

  public ChecklistItemJpaEntity(
      UUID id,
      UUID tenantId,
      UUID reservaId,
      String tipo,
      boolean completado,
      Instant completadoEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.reservaId = reservaId;
    this.tipo = tipo;
    this.completado = completado;
    this.completadoEn = completadoEn;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getReservaId() {
    return reservaId;
  }

  public String getTipo() {
    return tipo;
  }

  public boolean isCompletado() {
    return completado;
  }

  public Instant getCompletadoEn() {
    return completadoEn;
  }
}
