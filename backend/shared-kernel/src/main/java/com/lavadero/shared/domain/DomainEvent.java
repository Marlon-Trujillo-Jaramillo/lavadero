package com.lavadero.shared.domain;

import java.time.Instant;

/**
 * Contrato base para todo evento de dominio, sea interno a un módulo o compartido entre módulos
 * (estos últimos viven en el módulo `contracts` e implementan también esta interfaz).
 */
public interface DomainEvent {

  /** Momento en que ocurrió el hecho de negocio representado por el evento. */
  Instant occurredOn();
}
