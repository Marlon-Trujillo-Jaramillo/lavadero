package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Lista TODOS los servicios del tenant actual (activos e inactivos) — vista de administración. */
@Service
public class ListarServiciosUseCase implements UseCase<Void, List<ServicioDto>> {

  private final ServicioRepository servicioRepository;

  public ListarServiciosUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ServicioDto> execute(Void input) {
    return servicioRepository.findAllDelTenantActual().stream().map(ServicioMapper::toDto).toList();
  }
}
