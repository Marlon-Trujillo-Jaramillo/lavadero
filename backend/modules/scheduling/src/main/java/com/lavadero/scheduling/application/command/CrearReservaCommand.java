package com.lavadero.scheduling.application.command;

import java.time.Instant;
import java.util.UUID;

/**
 * {@code clienteId} viene de {@code PrincipalAutenticado} en el controller, nunca del body. {@code
 * vehiculoId} y {@code codigoCupon} son opcionales.
 */
public record CrearReservaCommand(
    UUID clienteId,
    UUID sucursalId,
    UUID servicioId,
    Instant fechaHoraInicio,
    UUID vehiculoId,
    String codigoCupon) {

  public CrearReservaCommand(
      UUID clienteId, UUID sucursalId, UUID servicioId, Instant fechaHoraInicio, UUID vehiculoId) {
    this(clienteId, sucursalId, servicioId, fechaHoraInicio, vehiculoId, null);
  }
}
