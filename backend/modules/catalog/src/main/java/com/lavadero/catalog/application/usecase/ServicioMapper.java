package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.model.Servicio;

/** Mapeo compartido dominio→DTO entre los casos de uso de este paquete. */
final class ServicioMapper {

  private ServicioMapper() {}

  static ServicioDto toDto(Servicio servicio) {
    return new ServicioDto(
        servicio.getId(),
        servicio.getNombre(),
        servicio.getDescripcion(),
        servicio.getDuracionEstimadaMinutos(),
        servicio.getPrecio().monto(),
        servicio.getPrecio().moneda().getCurrencyCode(),
        servicio.isActivo());
  }
}
