package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.VehiculoDto;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Vehículos activos del cliente actual — mismo patrón que {@code ListarMisReservasUseCase}. */
@Service
public class ListarMisVehiculosUseCase implements UseCase<UUID, List<VehiculoDto>> {

  private final VehiculoRepository vehiculoRepository;

  public ListarMisVehiculosUseCase(VehiculoRepository vehiculoRepository) {
    this.vehiculoRepository = vehiculoRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<VehiculoDto> execute(UUID clienteId) {
    return vehiculoRepository.findActivosByClienteId(clienteId).stream()
        .map(VehiculoMapper::toDto)
        .toList();
  }
}
