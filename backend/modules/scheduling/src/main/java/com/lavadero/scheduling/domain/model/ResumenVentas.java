package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.Money;
import java.util.List;

/**
 * Resumen de ventas (reservas COMPLETADA) en un rango de tiempo. No es un aggregate (sin identidad,
 * sin ciclo de vida): es un value object de solo lectura, resultado de una consulta agregada — ver
 * {@code ReservaRepository.obtenerResumenVentas}.
 */
public record ResumenVentas(
    Money ingresosTotales,
    int totalReservasCompletadas,
    List<ServicioPopular> serviciosMasPedidos) {}
