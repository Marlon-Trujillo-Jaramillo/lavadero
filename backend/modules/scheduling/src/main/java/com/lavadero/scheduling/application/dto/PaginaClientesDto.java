package com.lavadero.scheduling.application.dto;

import java.util.List;
import java.util.Map;

public record PaginaClientesDto(
    List<ClienteResumenDto> clientes,
    long total,
    int pagina,
    int tamano,
    Map<String, Long> porSegmento) {}
