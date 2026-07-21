package com.lavadero.scheduling.application.dto;

import java.util.UUID;

public record ServicioPopularDto(UUID servicioId, String nombreServicio, long cantidad) {}
