package com.lavadero.tenant.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.util.Objects;
import java.util.UUID;

/**
 * Sucursal física de un tenant. Vive en `tenant-management` (no en `scheduling`, que aún no existe)
 * porque toda cuenta necesita al menos una sucursal desde el momento del onboarding. El módulo de
 * scheduling, cuando se construya, añadirá horarios/capacidad detallada sobre esta misma entidad
 * (probablemente vía una tabla propia referenciando `sucursal.id`).
 *
 * <p>Es la primera entidad de negocio (no de plataforma) con {@code tenantId}: su tabla SÍ tiene
 * Row Level Security habilitado (ver migración V1__tenant_management.sql) y es también el primer
 * caso de uso del filtro de Hibernate a nivel de sesión (defensa en profundidad) configurado en
 * `identity-access`.
 */
public class Sucursal extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private String nombre;
  private String direccion;
  private int capacidadSimultanea;

  public Sucursal(
      UUID id, UUID tenantId, String nombre, String direccion, int capacidadSimultanea) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.nombre = requireTexto(nombre);
    this.direccion = direccion;
    if (capacidadSimultanea < 1) {
      throw new IllegalArgumentException("capacidadSimultanea debe ser al menos 1");
    }
    this.capacidadSimultanea = capacidadSimultanea;
  }

  public static Sucursal principal(UUID tenantId) {
    return new Sucursal(UUID.randomUUID(), tenantId, "Principal", null, 1);
  }

  /**
   * Alta de una sucursal adicional (no la "Principal" del onboarding, ver {@link
   * #principal(UUID)}), p. ej. cuando un lavadero abre una segunda sede.
   */
  public static Sucursal nueva(
      UUID tenantId, String nombre, String direccion, int capacidadSimultanea) {
    return new Sucursal(UUID.randomUUID(), tenantId, nombre, direccion, capacidadSimultanea);
  }

  public void actualizarDetalles(String nombre, String direccion, int capacidadSimultanea) {
    this.nombre = requireTexto(nombre);
    this.direccion = direccion;
    if (capacidadSimultanea < 1) {
      throw new IllegalArgumentException("capacidadSimultanea debe ser al menos 1");
    }
    this.capacidadSimultanea = capacidadSimultanea;
  }

  private static String requireTexto(String valor) {
    if (valor == null || valor.isBlank()) {
      throw new IllegalArgumentException("nombre no puede ser vacío");
    }
    return valor;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getNombre() {
    return nombre;
  }

  public String getDireccion() {
    return direccion;
  }

  public int getCapacidadSimultanea() {
    return capacidadSimultanea;
  }
}
