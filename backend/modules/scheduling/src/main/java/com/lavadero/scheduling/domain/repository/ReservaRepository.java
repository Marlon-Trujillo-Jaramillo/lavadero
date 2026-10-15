package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ResumenVentas;
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

  /**
   * Serializa la creación de reservas de una sucursal hasta el fin de la transacción en curso. Sin
   * esto, dos reservas simultáneas leen el mismo cupo libre y ambas se insertan (sobreventa).
   */
  void bloquearAgendaDeSucursal(UUID sucursalId);

  /** Agenda de una sucursal en [desde, hasta), cualquier estado — vista de empleado. */
  List<Reserva> findPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta);

  /**
   * Reservas de un cliente, más recientes primero ({@code fecha_hora_inicio} desc), como mucho
   * {@code limite}. {@code desde} opcional ({@code null} = sin cota inferior).
   */
  List<Reserva> findPorCliente(UUID clienteId, Instant desde, int limite);

  /**
   * Agrega las reservas COMPLETADA del tenant actual en [desde, hasta) — vista de
   * dashboard/reportes. {@code sucursalId} opcional ({@code null} = todo el tenant).
   */
  ResumenVentas obtenerResumenVentas(Instant desde, Instant hasta, UUID sucursalId);

  Reserva save(Reserva reserva);
}
