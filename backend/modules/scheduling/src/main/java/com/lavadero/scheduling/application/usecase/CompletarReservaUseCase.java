package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** El empleado marca el lavado como terminado. */
@Service
public class CompletarReservaUseCase implements UseCase<ReservaStaffCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;

  public CompletarReservaUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional
  public ReservaDto execute(ReservaStaffCommand input) {
    Reserva reserva =
        ReservaDelAlcance.cargar(reservaRepository, input.reservaId(), input.alcance());
    reserva.completar();
    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }
}
