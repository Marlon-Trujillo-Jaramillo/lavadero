package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ClienteResumenDto;
import com.lavadero.scheduling.application.dto.PaginaClientesDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record PaginaClientesResponse(
    List<Cliente> clientes, long total, int pagina, int tamano, Map<String, Long> porSegmento) {

  public record Cliente(
      UUID id,
      String nombre,
      String email,
      int visitas,
      BigDecimal gastoTotal,
      String moneda,
      Instant primeraVisita,
      Instant ultimaVisita,
      Instant proximaReserva,
      int vehiculosActivos,
      String segmento) {

    public static Cliente from(ClienteResumenDto dto) {
      return new Cliente(
          dto.id(),
          dto.nombre(),
          dto.email(),
          dto.visitas(),
          dto.gastoTotal(),
          dto.moneda(),
          dto.primeraVisita(),
          dto.ultimaVisita(),
          dto.proximaReserva(),
          dto.vehiculosActivos(),
          dto.segmento());
    }
  }

  public static PaginaClientesResponse from(PaginaClientesDto dto) {
    return new PaginaClientesResponse(
        dto.clientes().stream().map(Cliente::from).toList(),
        dto.total(),
        dto.pagina(),
        dto.tamano(),
        dto.porSegmento());
  }
}
