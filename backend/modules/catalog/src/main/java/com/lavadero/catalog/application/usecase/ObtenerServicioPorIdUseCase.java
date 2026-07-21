package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Punto de entrada público para que OTROS módulos (p. ej. scheduling) resuelvan un servicio por id.
 */
@Service
public class ObtenerServicioPorIdUseCase implements UseCase<UUID, ServicioDto> {

  private final ServicioRepository servicioRepository;

  public ObtenerServicioPorIdUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public ServicioDto execute(UUID servicioId) {
    Servicio servicio =
        servicioRepository
            .findById(servicioId)
            .orElseThrow(() -> NotFoundException.de("Servicio", servicioId));
    return ServicioMapper.toDto(servicio);
  }
}
