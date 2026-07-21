package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.command.CambiarEstadoServicioCommand;
import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Activa o desactiva un servicio (no lo elimina: un servicio inactivo deja de listarse a
 * clientes/empleados pero conserva su historial).
 */
@Service
public class CambiarEstadoServicioUseCase
    implements UseCase<CambiarEstadoServicioCommand, ServicioDto> {

  private final ServicioRepository servicioRepository;

  public CambiarEstadoServicioUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional
  public ServicioDto execute(CambiarEstadoServicioCommand input) {
    Servicio servicio =
        servicioRepository
            .findById(input.servicioId())
            .orElseThrow(() -> NotFoundException.de("Servicio", input.servicioId()));
    if (input.activo()) {
      servicio.activar();
    } else {
      servicio.desactivar();
    }
    return ServicioMapper.toDto(servicioRepository.save(servicio));
  }
}
