package com.lavadero.tenant.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/**
 * Entidad JPA de {@code Pago}. {@code @FilterDef} vive una sola vez, en {@code SucursalJpaEntity}
 * (mismo patrón que el resto de entidades tenant-scoped de este módulo).
 */
@Entity
@Table(name = "pago")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class PagoJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "subscription_plan_id", nullable = false)
  private UUID subscriptionPlanId;

  @Column(nullable = false)
  private BigDecimal monto;

  @Column(nullable = false)
  private String moneda;

  @Column(nullable = false)
  private String referencia;

  @Column(nullable = false)
  private String estado;

  @Column(name = "transaccion_externa_id")
  private String transaccionExternaId;

  @Column(name = "creado_en", nullable = false)
  private Instant creadoEn;

  protected PagoJpaEntity() {}

  public PagoJpaEntity(
      UUID id,
      UUID tenantId,
      UUID subscriptionPlanId,
      BigDecimal monto,
      String moneda,
      String referencia,
      String estado,
      String transaccionExternaId,
      Instant creadoEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.subscriptionPlanId = subscriptionPlanId;
    this.monto = monto;
    this.moneda = moneda;
    this.referencia = referencia;
    this.estado = estado;
    this.transaccionExternaId = transaccionExternaId;
    this.creadoEn = creadoEn;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSubscriptionPlanId() {
    return subscriptionPlanId;
  }

  public BigDecimal getMonto() {
    return monto;
  }

  public String getMoneda() {
    return moneda;
  }

  public String getReferencia() {
    return referencia;
  }

  public String getEstado() {
    return estado;
  }

  public String getTransaccionExternaId() {
    return transaccionExternaId;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
