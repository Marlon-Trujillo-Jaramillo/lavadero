package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.VehiculoDto;
import java.time.Instant;
import java.util.UUID;

public record VehiculoResponse(
    UUID id, String placa, String tipo, String marca, String color, Instant creadoEn) {

  public static VehiculoResponse from(VehiculoDto dto) {
    return new VehiculoResponse(
        dto.id(), dto.placa(), dto.tipo(), dto.marca(), dto.color(), dto.creadoEn());
  }
}
