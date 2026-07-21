package com.lavadero.catalog.application.command;

import java.math.BigDecimal;
import java.util.UUID;

public record ActualizarServicioCommand(
    UUID servicioId,
    String nombre,
    String descripcion,
    int duracionEstimadaMinutos,
    BigDecimal precio) {}
