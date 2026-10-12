package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.IncidenciaCategoria;
import java.util.UUID;

public record CrearIncidenciaCommand(
    UUID reportadoPorUsuarioId,
    UUID sucursalId,
    UUID reservaId,
    IncidenciaCategoria categoria,
    String descripcion) {}
