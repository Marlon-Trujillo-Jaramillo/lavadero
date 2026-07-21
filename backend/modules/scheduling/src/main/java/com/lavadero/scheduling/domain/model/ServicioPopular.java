package com.lavadero.scheduling.domain.model;

import java.util.UUID;

/**
 * Cuántas veces se reservó (y completó) un servicio en un rango — parte de {@link ResumenVentas}.
 */
public record ServicioPopular(UUID servicioId, String nombreServicio, long cantidad) {}
