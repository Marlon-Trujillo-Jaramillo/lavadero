package com.lavadero.scheduling.application.dto;

import java.util.List;

public record FichaClienteDto(
    ClienteResumenDto cliente,
    String servicioFavorito,
    List<VehiculoDto> vehiculos,
    List<VisitaClienteDto> historial) {}
