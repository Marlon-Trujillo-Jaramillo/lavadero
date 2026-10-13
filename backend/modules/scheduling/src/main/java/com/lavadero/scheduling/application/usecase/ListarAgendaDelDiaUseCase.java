package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.AgendaDiaQuery;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Agenda de una sucursal para un rango de tiempo (típicamente un día) — vista de empleado. */
@Service
public class ListarAgendaDelDiaUseCase implements UseCase<AgendaDiaQuery, List<ReservaDto>> {

  private final ReservaRepository reservaRepository;

  public ListarAgendaDelDiaUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ReservaDto> execute(AgendaDiaQuery input) {
    input.alcance().verificar(input.sucursalId());
    return reservaRepository
        .findPorSucursalYRango(input.sucursalId(), input.desde(), input.hasta())
        .stream()
        .map(ReservaMapper::toDto)
        .toList();
  }
}
