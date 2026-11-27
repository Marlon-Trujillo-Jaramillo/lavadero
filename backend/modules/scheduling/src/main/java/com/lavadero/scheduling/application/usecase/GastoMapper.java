package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.GastoDto;
import com.lavadero.scheduling.domain.model.gasto.Gasto;

final class GastoMapper {

  private GastoMapper() {}

  static GastoDto toDto(Gasto gasto) {
    return new GastoDto(
        gasto.getId(),
        gasto.getSucursalId().orElse(null),
        gasto.getFecha(),
        gasto.getCategoria(),
        gasto.getDescripcion(),
        gasto.getMonto().monto(),
        gasto.getMonto().moneda().getCurrencyCode(),
        gasto.getCreadoEn());
  }
}
