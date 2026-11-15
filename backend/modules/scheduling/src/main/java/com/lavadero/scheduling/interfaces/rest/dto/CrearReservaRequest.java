package com.lavadero.scheduling.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public record CrearReservaRequest(
    @NotNull UUID sucursalId,
    @NotNull UUID servicioId,
    @NotNull Instant fechaHoraInicio,
    UUID vehiculoId) {}
