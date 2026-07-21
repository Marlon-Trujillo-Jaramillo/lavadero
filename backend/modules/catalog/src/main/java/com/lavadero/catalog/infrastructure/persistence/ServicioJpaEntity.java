package com.lavadero.catalog.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import org.hibernate.annotations.Filter;
import org.hibernate.annotations.FilterDef;
import org.hibernate.annotations.ParamDef;

/**
 * Entidad JPA de {@code Servicio}. Mismas dos capas de aislamiento que {@code SucursalJpaEntity}
 * (tenant-management): RLS de Postgres (V5__catalog.sql) + este filtro de Hibernate a nivel de
 * sesión, habilitado por {@code TenantAwareTransactionAspect} (identity-access) aunque este módulo
 * no dependa de él directamente — el aspecto se registra una sola vez para toda la app porque
 * `bootstrap` depende de `identity-access`.
 */
@Entity
@Table(name = "servicio")
@FilterDef(name = "tenantFilter", parameters = @ParamDef(name = "tenantId", type = UUID.class))
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class ServicioJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(nullable = false)
  private String nombre;

  private String descripcion;

  @Column(name = "duracion_estimada_minutos", nullable = false)
  private int duracionEstimadaMinutos;

  @Column(nullable = false)
  private BigDecimal precio;

  @Column(nullable = false)
  private String moneda;

  @Column(nullable = false)
  private boolean activo;

  protected ServicioJpaEntity() {}

  public ServicioJpaEntity(
      UUID id,
      UUID tenantId,
      String nombre,
      String descripcion,
      int duracionEstimadaMinutos,
      BigDecimal precio,
      String moneda,
      boolean activo) {
    this.id = id;
    this.tenantId = tenantId;
    this.nombre = nombre;
    this.descripcion = descripcion;
    this.duracionEstimadaMinutos = duracionEstimadaMinutos;
    this.precio = precio;
    this.moneda = moneda;
    this.activo = activo;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getNombre() {
    return nombre;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public int getDuracionEstimadaMinutos() {
    return duracionEstimadaMinutos;
  }

  public BigDecimal getPrecio() {
    return precio;
  }

  public String getMoneda() {
    return moneda;
  }

  public boolean isActivo() {
    return activo;
  }
}
