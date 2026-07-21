package com.lavadero.scheduling.domain.service;

import com.lavadero.scheduling.domain.model.Reserva;
import java.time.Instant;
import java.util.List;

/**
 * Servicio de dominio (sin estado, sin I/O): dado cuántas reservas activas ya solapan un horario y
 * la capacidad simultánea de la sucursal, decide si hay cupo. El caso de uso es quien carga las
 * reservas activas del rango (vía {@code ReservaRepository}) y la capacidad (vía {@code
 * SucursalRepository}, tenant-management) — este servicio no conoce ningún repositorio.
 */
public final class DisponibilidadService {

  private DisponibilidadService() {}

  public static boolean hayCupo(
      int capacidadSimultanea,
      List<Reserva> reservasActivasDeLaSucursal,
      Instant nuevaInicio,
      Instant nuevaFin) {
    long solapadas =
        reservasActivasDeLaSucursal.stream()
            .filter(
                r -> seSolapan(r.getFechaHoraInicio(), r.getFechaHoraFin(), nuevaInicio, nuevaFin))
            .count();
    return solapadas < capacidadSimultanea;
  }

  private static boolean seSolapan(Instant aInicio, Instant aFin, Instant bInicio, Instant bFin) {
    return aInicio.isBefore(bFin) && bInicio.isBefore(aFin);
  }
}
