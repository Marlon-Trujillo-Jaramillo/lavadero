package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ChecklistItemDto;
import java.time.Instant;

public record ChecklistItemResponse(String tipo, String label, boolean completado, Instant completadoEn) {

  public static ChecklistItemResponse from(ChecklistItemDto dto) {
    return new ChecklistItemResponse(dto.tipo(), dto.label(), dto.completado(), dto.completadoEn());
  }
}
