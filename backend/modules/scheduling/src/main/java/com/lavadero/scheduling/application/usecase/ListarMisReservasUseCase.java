package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Reservas del cliente actual (cualquier estado) — vista de cliente. */
@Service
public class ListarMisReservasUseCase implements UseCase<UUID, List<ReservaDto>> {

  private final ReservaRepository reservaRepository;

  public ListarMisReservasUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ReservaDto> execute(UUID clienteId) {
    return reservaRepository.findPorCliente(clienteId).stream().map(ReservaMapper::toDto).toList();
  }
}
