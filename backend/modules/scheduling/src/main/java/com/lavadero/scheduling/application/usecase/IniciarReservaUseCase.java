package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** El empleado marca que el carro llegó y el lavado inició. */
@Service
public class IniciarReservaUseCase implements UseCase<ReservaStaffCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;

  public IniciarReservaUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional
  public ReservaDto execute(ReservaStaffCommand input) {
    Reserva reserva =
        ReservaDelAlcance.cargar(reservaRepository, input.reservaId(), input.alcance());
    reserva.iniciar();
    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }
}
