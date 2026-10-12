package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.domain.model.IncidenciaCategoria;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CrearIncidenciaRequest(
    @NotNull UUID sucursalId,
    UUID reservaId,
    @NotNull IncidenciaCategoria categoria,
    @NotBlank String descripcion) {}
