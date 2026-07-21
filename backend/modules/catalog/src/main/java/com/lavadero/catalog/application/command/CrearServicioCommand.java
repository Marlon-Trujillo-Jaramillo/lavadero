package com.lavadero.catalog.application.command;

import java.math.BigDecimal;

public record CrearServicioCommand(
    String nombre, String descripcion, int duracionEstimadaMinutos, BigDecimal precio) {}
