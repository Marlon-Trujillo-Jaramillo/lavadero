package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.Reserva;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia de {@link Reserva}. Igual que los demás repositorios del proyecto, no
 * filtra manualmente por tenant: eso es responsabilidad de RLS + el filtro de Hibernate (ver
 * V6__scheduling.sql).
 */
public interface ReservaRepository {

  Optional<Reserva> findById(UUID id);

  /**
   * Reservas ACTIVAS (no terminadas/canceladas) de una sucursal que se solapan con un rango — usado
   * por DisponibilidadService.
   */
  List<Reserva> findActivasPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta);

  /** Agenda del día de una sucursal (todas, cualquier estado) — vista de empleado. */
  List<Reserva> findPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta);

  List<Reserva> findPorCliente(UUID clienteId);

  Reserva save(Reserva reserva);
}
