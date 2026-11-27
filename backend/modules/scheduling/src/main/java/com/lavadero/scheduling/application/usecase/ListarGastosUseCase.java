package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ListarGastosQuery;
import com.lavadero.scheduling.application.dto.GastoDto;
import com.lavadero.scheduling.domain.repository.GastoRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Gastos del rango, el más reciente primero; respeta el alcance de sucursal del usuario. */
@Service
public class ListarGastosUseCase implements UseCase<ListarGastosQuery, List<GastoDto>> {

  private final GastoRepository gastoRepository;

  public ListarGastosUseCase(GastoRepository gastoRepository) {
    this.gastoRepository = gastoRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<GastoDto> execute(ListarGastosQuery input) {
    RangoReporte.validar(input.desde(), input.hasta());
    UUID sucursalId = input.alcance().resolverFiltro(input.sucursalId());
    return gastoRepository.listar(input.desde(), input.hasta(), sucursalId).stream()
        .map(GastoMapper::toDto)
        .toList();
  }
}
