package com.lavadero.scheduling.application.dto;

import java.time.Instant;

public record ChecklistItemDto(
    String tipo, String label, boolean completado, Instant completadoEn) {}
