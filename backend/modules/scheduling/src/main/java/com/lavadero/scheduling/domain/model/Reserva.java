package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Una reserva de un {@code Servicio} (catalog) en una {@code Sucursal} (tenant-management) para un
 * cliente, en un horario concreto. {@code duracionEstimadaMinutos} y {@code precio} se CONGELAN al
 * crear la reserva (copiados del Servicio en ese momento): si el catálogo cambia después, no debe
 * afectar reservas ya hechas.
 *
 * <p>Máquina de estados: PENDIENTE -&gt; EN_PROGRESO -&gt; COMPLETADA, con CANCELADA alcanzable
 * desde PENDIENTE o EN_PROGRESO. Las transiciones inválidas son un error de programación/uso
 * indebido del dominio (no un error de validación de input), por eso lanzan {@link
 * IllegalStateException} y no una excepción de aplicación.
 */
public class Reserva extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private final UUID sucursalId;
  private final UUID servicioId;
  private final UUID clienteId;
  private final Instant fechaHoraInicio;
  private final int duracionEstimadaMinutos;
  private final Money precio;
  private ReservaEstado estado;

  public Reserva(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      UUID servicioId,
      UUID clienteId,
      Instant fechaHoraInicio,
      int duracionEstimadaMinutos,
      Money precio,
      ReservaEstado estado) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.sucursalId = Objects.requireNonNull(sucursalId, "sucursalId no puede ser nulo");
    this.servicioId = Objects.requireNonNull(servicioId, "servicioId no puede ser nulo");
    this.clienteId = Objects.requireNonNull(clienteId, "clienteId no puede ser nulo");
    this.fechaHoraInicio =
        Objects.requireNonNull(fechaHoraInicio, "fechaHoraInicio no puede ser nula");
    if (duracionEstimadaMinutos < 1) {
      throw new IllegalArgumentException("duracionEstimadaMinutos debe ser al menos 1");
    }
    this.duracionEstimadaMinutos = duracionEstimadaMinutos;
    this.precio = Objects.requireNonNull(precio, "precio no puede ser nulo");
    this.estado = Objects.requireNonNull(estado, "estado no puede ser nulo");
  }

  public static Reserva nueva(
      UUID tenantId,
      UUID sucursalId,
      UUID servicioId,
      UUID clienteId,
      Instant fechaHoraInicio,
      int duracionEstimadaMinutos,
      Money precio) {
    return new Reserva(
        UUID.randomUUID(),
        tenantId,
        sucursalId,
        servicioId,
        clienteId,
        fechaHoraInicio,
        duracionEstimadaMinutos,
        precio,
        ReservaEstado.PENDIENTE);
  }

  public void iniciar() {
    if (estado != ReservaEstado.PENDIENTE) {
      throw new IllegalStateException(
          "Solo una reserva PENDIENTE puede iniciarse (estado actual: %s)".formatted(estado));
    }
    estado = ReservaEstado.EN_PROGRESO;
  }

  public void completar() {
    if (estado != ReservaEstado.EN_PROGRESO) {
      throw new IllegalStateException(
          "Solo una reserva EN_PROGRESO puede completarse (estado actual: %s)".formatted(estado));
    }
    estado = ReservaEstado.COMPLETADA;
  }

  /**
   * Solo una reserva que no ha iniciado puede cancelarse (ver docs/specs/002-agenda-reservas.md).
   */
  public void cancelar() {
    if (estado != ReservaEstado.PENDIENTE) {
      throw new IllegalStateException(
          "Solo una reserva PENDIENTE puede cancelarse (estado actual: %s)".formatted(estado));
    }
    estado = ReservaEstado.CANCELADA;
  }

  public Instant getFechaHoraFin() {
    return fechaHoraInicio.plus(Duration.ofMinutes(duracionEstimadaMinutos));
  }

  /** Activas = ocupan cupo de la sucursal (no terminadas ni canceladas). */
  public boolean estaActiva() {
    return estado == ReservaEstado.PENDIENTE || estado == ReservaEstado.EN_PROGRESO;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSucursalId() {
    return sucursalId;
  }

  public UUID getServicioId() {
    return servicioId;
  }

  public UUID getClienteId() {
    return clienteId;
  }

  public Instant getFechaHoraInicio() {
    return fechaHoraInicio;
  }

  public int getDuracionEstimadaMinutos() {
    return duracionEstimadaMinutos;
  }

  public Money getPrecio() {
    return precio;
  }

  public ReservaEstado getEstado() {
    return estado;
  }
}
