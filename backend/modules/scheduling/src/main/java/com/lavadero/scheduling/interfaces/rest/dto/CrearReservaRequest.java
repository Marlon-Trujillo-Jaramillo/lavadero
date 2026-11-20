package com.lavadero.scheduling.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public record CrearReservaRequest(
    @NotNull UUID sucursalId,
    @NotNull UUID servicioId,
    @NotNull Instant fechaHoraInicio,
    UUID vehiculoId,
    @Size(max = 40) String codigoCupon) {}
