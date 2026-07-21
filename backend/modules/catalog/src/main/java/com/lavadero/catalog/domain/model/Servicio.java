package com.lavadero.catalog.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.util.Objects;
import java.util.UUID;

/**
 * Un servicio del catálogo de un tenant (p. ej. "Lavado básico", "Lavado completo + encerado"): qué
 * se ofrece, cuánto se cobra y cuánto tarda. Precio y duración son tenant-wide en esta primera
 * versión (sin variación por sucursal); ver `docs/specs/001-catalogo-servicios.md` para el porqué.
 *
 * <p>Es la primera entidad de negocio del módulo `catalog`: su tabla tiene Row Level Security
 * habilitado igual que `sucursal`/`usuario` (ver migración V5__catalog.sql).
 */
public class Servicio extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private String nombre;
  private String descripcion;
  private int duracionEstimadaMinutos;
  private Money precio;
  private boolean activo;

  public Servicio(
      UUID id,
      UUID tenantId,
      String nombre,
      String descripcion,
      int duracionEstimadaMinutos,
      Money precio,
      boolean activo) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.nombre = requireNombre(nombre);
    this.descripcion = descripcion;
    this.duracionEstimadaMinutos = requireDuracionValida(duracionEstimadaMinutos);
    this.precio = Objects.requireNonNull(precio, "precio no puede ser nulo");
    this.activo = activo;
  }

  public static Servicio nuevo(
      UUID tenantId, String nombre, String descripcion, int duracionEstimadaMinutos, Money precio) {
    return new Servicio(
        UUID.randomUUID(), tenantId, nombre, descripcion, duracionEstimadaMinutos, precio, true);
  }

  public void actualizarDetalles(String nombre, String descripcion, int duracionEstimadaMinutos) {
    this.nombre = requireNombre(nombre);
    this.descripcion = descripcion;
    this.duracionEstimadaMinutos = requireDuracionValida(duracionEstimadaMinutos);
  }

  public void actualizarPrecio(Money nuevoPrecio) {
    this.precio = Objects.requireNonNull(nuevoPrecio, "precio no puede ser nulo");
  }

  public void activar() {
    this.activo = true;
  }

  public void desactivar() {
    this.activo = false;
  }

  private static String requireNombre(String valor) {
    if (valor == null || valor.isBlank()) {
      throw new IllegalArgumentException("nombre no puede ser vacío");
    }
    return valor;
  }

  private static int requireDuracionValida(int minutos) {
    if (minutos < 1) {
      throw new IllegalArgumentException("duracionEstimadaMinutos debe ser al menos 1");
    }
    return minutos;
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

  public Money getPrecio() {
    return precio;
  }

  public boolean isActivo() {
    return activo;
  }
}
