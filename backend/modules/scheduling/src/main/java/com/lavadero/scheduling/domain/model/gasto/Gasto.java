package com.lavadero.scheduling.domain.model.gasto;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Un gasto operativo del lavadero. Con {@code sucursalId} se imputa a una sucursal; sin él es un
 * gasto general del negocio. El monto siempre es positivo (un ingreso no es un gasto negativo).
 */
public class Gasto extends AggregateRoot<UUID> {

  static final int DESCRIPCION_MAX = 120;

  private final UUID tenantId;
  private final UUID sucursalId;
  private final LocalDate fecha;
  private final CategoriaGasto categoria;
  private final String descripcion;
  private final Money monto;
  private final Instant creadoEn;

  public Gasto(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      LocalDate fecha,
      CategoriaGasto categoria,
      String descripcion,
      Money monto,
      Instant creadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.sucursalId = sucursalId;
    this.fecha = Objects.requireNonNull(fecha, "fecha no puede ser nula");
    this.categoria = Objects.requireNonNull(categoria, "categoria no puede ser nula");
    this.descripcion = descripcionValida(descripcion);
    this.monto = Objects.requireNonNull(monto, "monto no puede ser nulo");
    if (!monto.esMayorQue(Money.cero(monto.moneda()))) {
      throw new IllegalArgumentException("El monto del gasto debe ser mayor que cero");
    }
    this.creadoEn = Objects.requireNonNull(creadoEn, "creadoEn no puede ser nulo");
  }

  public static Gasto nuevo(
      UUID tenantId,
      UUID sucursalId,
      LocalDate fecha,
      CategoriaGasto categoria,
      String descripcion,
      Money monto,
      Instant ahora) {
    return new Gasto(
        UUID.randomUUID(), tenantId, sucursalId, fecha, categoria, descripcion, monto, ahora);
  }

  private static String descripcionValida(String descripcion) {
    Objects.requireNonNull(descripcion, "descripcion no puede ser nula");
    String limpio = descripcion.strip();
    if (limpio.isEmpty() || limpio.length() > DESCRIPCION_MAX) {
      throw new IllegalArgumentException(
          "La descripción del gasto debe tener entre 1 y " + DESCRIPCION_MAX + " caracteres");
    }
    return limpio;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public Optional<UUID> getSucursalId() {
    return Optional.ofNullable(sucursalId);
  }

  public LocalDate getFecha() {
    return fecha;
  }

  public CategoriaGasto getCategoria() {
    return categoria;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public Money getMonto() {
    return monto;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
