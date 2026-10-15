package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.MisReservasQuery;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Reservas del cliente actual (cualquier estado), más recientes primero — vista de cliente. */
@Service
public class ListarMisReservasUseCase implements UseCase<MisReservasQuery, List<ReservaDto>> {

  private final ReservaRepository reservaRepository;

  public ListarMisReservasUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ReservaDto> execute(MisReservasQuery input) {
    return reservaRepository
        .findPorCliente(input.clienteId(), input.desde(), input.limite())
        .stream()
        .map(ReservaMapper::toDto)
        .toList();
  }
}
