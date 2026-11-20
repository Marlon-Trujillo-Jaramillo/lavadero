package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.FichaClienteDto;
import com.lavadero.scheduling.application.dto.VisitaClienteDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record FichaClienteResponse(
    PaginaClientesResponse.Cliente cliente,
    String servicioFavorito,
    List<VehiculoResponse> vehiculos,
    List<Visita> historial) {

  public record Visita(
      UUID reservaId,
      Instant fecha,
      String servicio,
      String sucursal,
      String estado,
      BigDecimal precio,
      String moneda,
      String placa) {

    static Visita from(VisitaClienteDto dto) {
      return new Visita(
          dto.reservaId(),
          dto.fecha(),
          dto.servicio(),
          dto.sucursal(),
          dto.estado(),
          dto.precio(),
          dto.moneda(),
          dto.placa());
    }
  }

  public static FichaClienteResponse from(FichaClienteDto dto) {
    return new FichaClienteResponse(
        PaginaClientesResponse.Cliente.from(dto.cliente()),
        dto.servicioFavorito(),
        dto.vehiculos().stream().map(VehiculoResponse::from).toList(),
        dto.historial().stream().map(Visita::from).toList());
  }
}
