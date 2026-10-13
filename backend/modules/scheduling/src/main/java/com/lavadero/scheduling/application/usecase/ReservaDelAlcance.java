package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/**
 * Carga una reserva (RLS ya la acota al tenant) y verifica que caiga dentro del alcance del staff
 * que la pide — compartido por todas las acciones de staff sobre una reserva concreta.
 */
final class ReservaDelAlcance {

  private ReservaDelAlcance() {}

  static Reserva cargar(
      ReservaRepository reservaRepository, UUID reservaId, AlcanceSucursal alcance) {
    Reserva reserva =
        reservaRepository
            .findById(reservaId)
            .orElseThrow(() -> NotFoundException.de("Reserva", reservaId));
    alcance.verificar(reserva.getSucursalId());
    return reserva;
  }
}
