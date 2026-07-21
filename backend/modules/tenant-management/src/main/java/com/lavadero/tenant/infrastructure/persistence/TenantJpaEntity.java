package com.lavadero.tenant.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Entidad JPA de {@code Tenant}. Es la raíz de plataforma: su tabla NO tiene RLS habilitado (ver
 * V1__tenant_management.sql), a diferencia de `sucursal`.
 */
@Entity
@Table(name = "tenant")
public class TenantJpaEntity {

  @Id private UUID id;

  @Column(nullable = false)
  private String nombre;

  @Column(nullable = false)
  private String nit;

  @Column(nullable = false, unique = true)
  private String slug;

  @Column(nullable = false)
  private String estado;

  @Column(name = "subscription_plan_id", nullable = false)
  private UUID subscriptionPlanId;

  @Column(name = "fecha_creacion", nullable = false)
  private Instant fechaCreacion;

  protected TenantJpaEntity() {}

  public TenantJpaEntity(
      UUID id,
      String nombre,
      String nit,
      String slug,
      String estado,
      UUID subscriptionPlanId,
      Instant fechaCreacion) {
    this.id = id;
    this.nombre = nombre;
    this.nit = nit;
    this.slug = slug;
    this.estado = estado;
    this.subscriptionPlanId = subscriptionPlanId;
    this.fechaCreacion = fechaCreacion;
  }

  public UUID getId() {
    return id;
  }

  public String getNombre() {
    return nombre;
  }

  public String getNit() {
    return nit;
  }

  public String getSlug() {
    return slug;
  }

  public String getEstado() {
    return estado;
  }

  public UUID getSubscriptionPlanId() {
    return subscriptionPlanId;
  }

  public Instant getFechaCreacion() {
    return fechaCreacion;
  }
}
