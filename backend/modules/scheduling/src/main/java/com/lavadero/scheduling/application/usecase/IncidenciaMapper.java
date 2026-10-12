package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.IncidenciaDto;
import com.lavadero.scheduling.domain.model.Incidencia;

final class IncidenciaMapper {

  private IncidenciaMapper() {}

  static IncidenciaDto toDto(Incidencia incidencia) {
    return new IncidenciaDto(
        incidencia.getId(),
        incidencia.getSucursalId(),
        incidencia.getReservaId().orElse(null),
        incidencia.getCategoria().name(),
        incidencia.getDescripcion(),
        incidencia.getCreadoEn());
  }
}
