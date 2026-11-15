package com.lavadero.scheduling.domain.model;

import java.util.Objects;
import java.util.UUID;

/**
 * El vehículo elegido en una reserva, con su placa congelada al momento de reservar (igual que el
 * precio y la duración): si el cliente archiva el vehículo después, la reserva conserva la placa.
 */
public record VehiculoReservado(UUID vehiculoId, Placa placa) {

  public VehiculoReservado {
    Objects.requireNonNull(vehiculoId, "vehiculoId no puede ser nulo");
    Objects.requireNonNull(placa, "placa no puede ser nula");
  }
}
