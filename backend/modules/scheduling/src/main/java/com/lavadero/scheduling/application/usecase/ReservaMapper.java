package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.VehiculoReservado;

/**
 * Mapeo compartido dominio→DTO entre los casos de uso de este paquete (mismo patrón que catalog).
 */
final class ReservaMapper {

  private ReservaMapper() {}

  static ReservaDto toDto(Reserva reserva) {
    return new ReservaDto(
        reserva.getId(),
        reserva.getSucursalId(),
        reserva.getServicioId(),
        reserva.getClienteId(),
        reserva.getFechaHoraInicio(),
        reserva.getFechaHoraFin(),
        reserva.getDuracionEstimadaMinutos(),
        reserva.getPrecio().monto(),
        reserva.getPrecio().moneda().getCurrencyCode(),
        reserva.getEstado().name(),
        reserva.getVehiculo().map(VehiculoReservado::vehiculoId).orElse(null),
        reserva.getVehiculo().map(v -> v.placa().valor()).orElse(null));
  }
}
