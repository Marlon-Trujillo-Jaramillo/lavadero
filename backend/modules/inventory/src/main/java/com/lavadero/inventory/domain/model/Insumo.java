package com.lavadero.inventory.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Currency;
import java.util.Objects;
import java.util.UUID;

/**
 * Algo que el lavadero compra y gasta: shampoo, cera, microfibras. El costo es por unidad de medida
 * (1 ml, 1 g, 1 unidad) y admite fracciones de peso, porque 1 ml de shampoo cuesta centavos; por
 * eso no es un {@code Money} (que redondea a 2 decimales).
 */
public class Insumo extends AggregateRoot<UUID> {

  static final int NOMBRE_MAX = 60;
  static final int COSTO_DECIMALES = 4;

  private final UUID tenantId;
  private final String nombre;
  private final UnidadMedida unidad;
  private final BigDecimal costoUnitario;
  private final Currency moneda;
  private final boolean activo;
  private final Instant creadoEn;

  public Insumo(
      UUID id,
      UUID tenantId,
      String nombre,
      UnidadMedida unidad,
      BigDecimal costoUnitario,
      Currency moneda,
      boolean activo,
      Instant creadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    Objects.requireNonNull(nombre, "nombre no puede ser nulo");
    String limpio = nombre.strip();
    if (limpio.isEmpty() || limpio.length() > NOMBRE_MAX) {
      throw new IllegalArgumentException(
          "El nombre del insumo debe tener entre 1 y " + NOMBRE_MAX + " caracteres");
    }
    this.nombre = limpio;
    this.unidad = Objects.requireNonNull(unidad, "unidad no puede ser nula");
    Objects.requireNonNull(costoUnitario, "costoUnitario no puede ser nulo");
    if (costoUnitario.signum() < 0) {
      throw new IllegalArgumentException("El costo del insumo no puede ser negativo");
    }
    if (costoUnitario.stripTrailingZeros().scale() > COSTO_DECIMALES) {
      throw new IllegalArgumentException(
          "El costo por unidad admite hasta " + COSTO_DECIMALES + " decimales");
    }
    this.costoUnitario = costoUnitario;
    this.moneda = Objects.requireNonNull(moneda, "moneda no puede ser nula");
    this.activo = activo;
    this.creadoEn = Objects.requireNonNull(creadoEn, "creadoEn no puede ser nulo");
  }

  public static Insumo nuevo(
      UUID tenantId,
      String nombre,
      UnidadMedida unidad,
      BigDecimal costoUnitario,
      Currency moneda,
      Instant ahora) {
    return new Insumo(
        UUID.randomUUID(), tenantId, nombre, unidad, costoUnitario, moneda, true, ahora);
  }

  /** Costo de gastar {@code cantidad} de este insumo, sin redondear. */
  public BigDecimal costoDe(BigDecimal cantidad) {
    return costoUnitario.multiply(cantidad);
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getNombre() {
    return nombre;
  }

  public UnidadMedida getUnidad() {
    return unidad;
  }

  public BigDecimal getCostoUnitario() {
    return costoUnitario;
  }

  public Currency getMoneda() {
    return moneda;
  }

  public boolean isActivo() {
    return activo;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
