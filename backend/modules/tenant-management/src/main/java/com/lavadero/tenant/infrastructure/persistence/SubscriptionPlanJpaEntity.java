package com.lavadero.tenant.infrastructure.persistence;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "subscription_plan")
public class SubscriptionPlanJpaEntity {

  @Id private UUID id;

  @Column(nullable = false)
  private String nombre;

  @Column(nullable = false)
  private BigDecimal precio;

  @Column(nullable = false)
  private String moneda;

  @Column(name = "max_sucursales", nullable = false)
  private int maxSucursales;

  @Column(name = "max_empleados", nullable = false)
  private int maxEmpleados;

  @ElementCollection
  @CollectionTable(
      name = "subscription_plan_feature",
      joinColumns = @JoinColumn(name = "subscription_plan_id"))
  @Column(name = "feature")
  private List<String> features = new ArrayList<>();

  protected SubscriptionPlanJpaEntity() {}

  public SubscriptionPlanJpaEntity(
      UUID id,
      String nombre,
      BigDecimal precio,
      String moneda,
      int maxSucursales,
      int maxEmpleados,
      List<String> features) {
    this.id = id;
    this.nombre = nombre;
    this.precio = precio;
    this.moneda = moneda;
    this.maxSucursales = maxSucursales;
    this.maxEmpleados = maxEmpleados;
    this.features = new ArrayList<>(features);
  }

  public UUID getId() {
    return id;
  }

  public String getNombre() {
    return nombre;
  }

  public BigDecimal getPrecio() {
    return precio;
  }

  public String getMoneda() {
    return moneda;
  }

  public int getMaxSucursales() {
    return maxSucursales;
  }

  public int getMaxEmpleados() {
    return maxEmpleados;
  }

  public List<String> getFeatures() {
    return features;
  }
}
