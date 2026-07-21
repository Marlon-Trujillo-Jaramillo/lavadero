package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** El empleado marca que el carro llegó y el lavado inició. */
@Service
public class IniciarReservaUseCase implements UseCase<UUID, ReservaDto> {

  private final ReservaRepository reservaRepository;

  public IniciarReservaUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional
  public ReservaDto execute(UUID reservaId) {
    Reserva reserva =
        reservaRepository
            .findById(reservaId)
            .orElseThrow(() -> NotFoundException.de("Reserva", reservaId));
    reserva.iniciar();
    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }
}
