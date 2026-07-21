package com.lavadero.tenant.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Plan de suscripción que un tenant contrata. Define límites de uso (sucursales, empleados) y
 * features habilitadas. En esta fase es un catálogo simple gestionado por la plataforma (no
 * autogestionable por el tenant todavía).
 */
public class SubscriptionPlan extends AggregateRoot<UUID> {

  private final String nombre;
  private final Money precio;
  private final int maxSucursales;
  private final int maxEmpleados;
  private final List<String> features;

  public SubscriptionPlan(
      UUID id,
      String nombre,
      Money precio,
      int maxSucursales,
      int maxEmpleados,
      List<String> features) {
    super(id);
    this.nombre = Objects.requireNonNull(nombre);
    this.precio = Objects.requireNonNull(precio);
    if (maxSucursales < 1) {
      throw new IllegalArgumentException("maxSucursales debe ser al menos 1");
    }
    if (maxEmpleados < 1) {
      throw new IllegalArgumentException("maxEmpleados debe ser al menos 1");
    }
    this.maxSucursales = maxSucursales;
    this.maxEmpleados = maxEmpleados;
    this.features = List.copyOf(features);
  }

  public String getNombre() {
    return nombre;
  }

  public Money getPrecio() {
    return precio;
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
