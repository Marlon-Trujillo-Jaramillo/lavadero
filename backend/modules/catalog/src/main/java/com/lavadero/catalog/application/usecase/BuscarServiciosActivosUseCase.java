package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lista solo los servicios ACTIVOS del tenant actual — vista de cliente/empleado (nunca deben ver
 * servicios que el admin dejó de ofrecer).
 */
@Service
public class BuscarServiciosActivosUseCase implements UseCase<Void, List<ServicioDto>> {

  private final ServicioRepository servicioRepository;

  public BuscarServiciosActivosUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ServicioDto> execute(Void input) {
    return servicioRepository.findActivosDelTenantActual().stream()
        .map(ServicioMapper::toDto)
        .toList();
  }
}
