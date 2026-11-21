package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.CancelarReservaCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Cancela una reserva PENDIENTE — solo el cliente dueño o personal del lavadero pueden hacerlo. */
@Service
public class CancelarReservaUseCase implements UseCase<CancelarReservaCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;
  private final PromocionRepository promocionRepository;

  public CancelarReservaUseCase(
      ReservaRepository reservaRepository, PromocionRepository promocionRepository) {
    this.reservaRepository = reservaRepository;
    this.promocionRepository = promocionRepository;
  }

  @Override
  @Transactional
  public ReservaDto execute(CancelarReservaCommand input) {
    Reserva reserva =
        reservaRepository
            .findById(input.reservaId())
            .orElseThrow(() -> NotFoundException.de("Reserva", input.reservaId()));

    boolean esDuenio = reserva.getClienteId().equals(input.solicitanteId());
    if (!esDuenio && !input.solicitanteEsStaff()) {
      throw new ForbiddenException(
          "Solo el cliente dueño de la reserva o el personal del lavadero pueden cancelarla");
    }
    if (!esDuenio) {
      input.alcance().verificar(reserva.getSucursalId());
    }

    reserva.cancelar();
    // El cupo de la promoción vuelve a estar disponible: un cupón de "primeros 50" no se pierde
    // porque alguien canceló.
    reserva.getPromocion().ifPresent(p -> promocionRepository.liberarUso(p.promocionId()));
    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }
}
