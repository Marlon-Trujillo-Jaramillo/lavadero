package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.VehiculoDto;
import com.lavadero.scheduling.domain.model.Vehiculo;

final class VehiculoMapper {

  private VehiculoMapper() {}

  static VehiculoDto toDto(Vehiculo vehiculo) {
    return new VehiculoDto(
        vehiculo.getId(),
        vehiculo.getPlaca().valor(),
        vehiculo.getTipo().name(),
        vehiculo.getMarca().orElse(null),
        vehiculo.getColor().orElse(null),
        vehiculo.getCreadoEn());
  }
}
