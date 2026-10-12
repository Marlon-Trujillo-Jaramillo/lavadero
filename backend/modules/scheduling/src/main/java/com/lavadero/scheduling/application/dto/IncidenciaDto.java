package com.lavadero.scheduling.application.dto;

import java.time.Instant;
import java.util.UUID;

public record IncidenciaDto(
    UUID id,
    UUID sucursalId,
    UUID reservaId,
    String categoria,
    String descripcion,
    Instant creadoEn) {}
