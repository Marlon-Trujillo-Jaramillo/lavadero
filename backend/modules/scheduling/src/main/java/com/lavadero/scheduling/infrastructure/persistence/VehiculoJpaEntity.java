package com.lavadero.scheduling.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/**
 * El {@code @FilterDef} vive una sola vez en {@code SucursalJpaEntity}; aquí solo se referencia.
 */
@Entity
@Table(name = "vehiculo")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class VehiculoJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "cliente_id", nullable = false)
  private UUID clienteId;

  @Column(nullable = false)
  private String placa;

  @Column(nullable = false)
  private String tipo;

  private String marca;

  private String color;

  @Column(nullable = false)
  private boolean activo;

  @Column(name = "creado_en", nullable = false)
  private Instant creadoEn;

  protected VehiculoJpaEntity() {}

  public VehiculoJpaEntity(
      UUID id,
      UUID tenantId,
      UUID clienteId,
      String placa,
      String tipo,
      String marca,
      String color,
      boolean activo,
      Instant creadoEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.clienteId = clienteId;
    this.placa = placa;
    this.tipo = tipo;
    this.marca = marca;
    this.color = color;
    this.activo = activo;
    this.creadoEn = creadoEn;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getClienteId() {
    return clienteId;
  }

  public String getPlaca() {
    return placa;
  }

  public String getTipo() {
    return tipo;
  }

  public String getMarca() {
    return marca;
  }

  public String getColor() {
    return color;
  }

  public boolean isActivo() {
    return activo;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
