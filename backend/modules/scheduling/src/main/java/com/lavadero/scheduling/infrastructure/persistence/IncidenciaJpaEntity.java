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
@Table(name = "incidencia")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class IncidenciaJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "sucursal_id", nullable = false)
  private UUID sucursalId;

  @Column(name = "reserva_id")
  private UUID reservaId;

  @Column(name = "reportado_por_usuario_id", nullable = false)
  private UUID reportadoPorUsuarioId;

  @Column(nullable = false)
  private String categoria;

  @Column(nullable = false)
  private String descripcion;

  @Column(name = "creado_en", nullable = false)
  private Instant creadoEn;

  protected IncidenciaJpaEntity() {}

  public IncidenciaJpaEntity(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      UUID reservaId,
      UUID reportadoPorUsuarioId,
      String categoria,
      String descripcion,
      Instant creadoEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.sucursalId = sucursalId;
    this.reservaId = reservaId;
    this.reportadoPorUsuarioId = reportadoPorUsuarioId;
    this.categoria = categoria;
    this.descripcion = descripcion;
    this.creadoEn = creadoEn;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSucursalId() {
    return sucursalId;
  }

  public UUID getReservaId() {
    return reservaId;
  }

  public UUID getReportadoPorUsuarioId() {
    return reportadoPorUsuarioId;
  }

  public String getCategoria() {
    return categoria;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
