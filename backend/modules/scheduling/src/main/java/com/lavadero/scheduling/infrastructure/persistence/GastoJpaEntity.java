package com.lavadero.scheduling.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/** El {@code @FilterDef} vive en {@code SucursalJpaEntity}; aquí solo se referencia. */
@Entity
@Table(name = "gasto")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class GastoJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "sucursal_id")
  private UUID sucursalId;

  @Column(nullable = false)
  private LocalDate fecha;

  @Column(nullable = false)
  private String categoria;

  @Column(nullable = false)
  private String descripcion;

  @Column(nullable = false)
  private BigDecimal monto;

  @Column(nullable = false)
  private String moneda;

  @Column(name = "creado_en", nullable = false)
  private Instant creadoEn;

  protected GastoJpaEntity() {}

  GastoJpaEntity(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      LocalDate fecha,
      String categoria,
      String descripcion,
      BigDecimal monto,
      String moneda,
      Instant creadoEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.sucursalId = sucursalId;
    this.fecha = fecha;
    this.categoria = categoria;
    this.descripcion = descripcion;
    this.monto = monto;
    this.moneda = moneda;
    this.creadoEn = creadoEn;
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  UUID getSucursalId() {
    return sucursalId;
  }

  LocalDate getFecha() {
    return fecha;
  }

  String getCategoria() {
    return categoria;
  }

  String getDescripcion() {
    return descripcion;
  }

  BigDecimal getMonto() {
    return monto;
  }

  String getMoneda() {
    return moneda;
  }

  Instant getCreadoEn() {
    return creadoEn;
  }
}
