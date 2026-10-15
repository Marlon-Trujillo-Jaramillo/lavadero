package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Un problema reportado por un empleado durante o después de un servicio (daño al vehículo, cliente
 * ausente, insumo faltante, otro). {@code reservaId} es opcional: un insumo faltante no está atado
 * a una reserva concreta — ver docs/specs/006-checklist-incidencias.md.
 */
public class Incidencia extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private final UUID sucursalId;
  private final UUID reservaId;
  private final UUID reportadoPorUsuarioId;
  private final IncidenciaCategoria categoria;
  private final String descripcion;
  private final Instant creadoEn;

  public Incidencia(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      UUID reservaId,
      UUID reportadoPorUsuarioId,
      IncidenciaCategoria categoria,
      String descripcion,
      Instant creadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.sucursalId = Objects.requireNonNull(sucursalId, "sucursalId no puede ser nulo");
    this.reservaId = reservaId;
    this.reportadoPorUsuarioId =
        Objects.requireNonNull(reportadoPorUsuarioId, "reportadoPorUsuarioId no puede ser nulo");
    this.categoria = Objects.requireNonNull(categoria, "categoria no puede ser nula");
    if (descripcion == null || descripcion.isBlank()) {
      throw new IllegalArgumentException("descripcion no puede estar vacía");
    }
    this.descripcion = descripcion;
    this.creadoEn = Objects.requireNonNull(creadoEn, "creadoEn no puede ser nulo");
  }

  public static Incidencia nueva(
      UUID tenantId,
      UUID sucursalId,
      UUID reservaId,
      UUID reportadoPorUsuarioId,
      IncidenciaCategoria categoria,
      String descripcion) {
    return new Incidencia(
        UUID.randomUUID(),
        tenantId,
        sucursalId,
        reservaId,
        reportadoPorUsuarioId,
        categoria,
        descripcion,
        Instant.now());
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSucursalId() {
    return sucursalId;
  }

  public Optional<UUID> getReservaId() {
    return Optional.ofNullable(reservaId);
  }

  public UUID getReportadoPorUsuarioId() {
    return reportadoPorUsuarioId;
  }

  public IncidenciaCategoria getCategoria() {
    return categoria;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
