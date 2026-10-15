package com.lavadero.scheduling.application.command;

import java.time.Instant;
import java.util.UUID;

/** {@code clienteId} viene de {@code PrincipalAutenticado} en el controller, nunca del body. */
public record CrearReservaCommand(
    UUID clienteId, UUID sucursalId, UUID servicioId, Instant fechaHoraInicio) {}
