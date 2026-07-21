package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.util.List;

public record ResumenVentasDto(
    BigDecimal ingresosTotales,
    String moneda,
    int totalReservasCompletadas,
    List<ServicioPopularDto> serviciosMasPedidos) {}
