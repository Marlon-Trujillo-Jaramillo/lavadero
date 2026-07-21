package com.lavadero.scheduling.domain.model;

/**
 * Estado de una {@link Reserva}. Sin un estado "CONFIRMADA" separado: esta primera versión no tiene
 * aprobación manual (fricción innecesaria para un MVP) — PENDIENTE ya implica confirmada, la
 * capacidad se valida al crearla (ver {@code DisponibilidadService}).
 */
public enum ReservaEstado {
  PENDIENTE,
  EN_PROGRESO,
  COMPLETADA,
  CANCELADA
}
