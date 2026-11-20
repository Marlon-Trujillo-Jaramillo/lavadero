package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ClienteResumenDto;
import com.lavadero.scheduling.application.dto.VisitaClienteDto;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.VisitaCliente;

final class ClienteCrmMapper {

  private ClienteCrmMapper() {}

  static ClienteResumenDto toDto(ClienteResumen c) {
    return new ClienteResumenDto(
        c.id(),
        c.nombre(),
        c.email(),
        c.visitas(),
        c.gastoTotal().monto(),
        c.gastoTotal().moneda().getCurrencyCode(),
        c.primeraVisita(),
        c.ultimaVisita(),
        c.proximaReserva(),
        c.vehiculosActivos(),
        c.segmento().name());
  }

  static VisitaClienteDto toDto(VisitaCliente v) {
    return new VisitaClienteDto(
        v.reservaId(),
        v.fecha(),
        v.servicio(),
        v.sucursal(),
        v.estado().name(),
        v.precio().monto(),
        v.precio().moneda().getCurrencyCode(),
        v.placa());
  }
}
