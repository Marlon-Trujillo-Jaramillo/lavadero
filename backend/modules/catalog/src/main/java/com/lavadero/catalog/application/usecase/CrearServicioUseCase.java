package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.command.CrearServicioCommand;
import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Da de alta un servicio en el catálogo del tenant actual (resuelto de {@link TenantContext}). */
@Service
public class CrearServicioUseCase implements UseCase<CrearServicioCommand, ServicioDto> {

  private final ServicioRepository servicioRepository;

  public CrearServicioUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional
  public ServicioDto execute(CrearServicioCommand input) {
    Servicio servicio =
        Servicio.nuevo(
            TenantContext.requerido(),
            input.nombre(),
            input.descripcion(),
            input.duracionEstimadaMinutos(),
            Money.cop(input.precio()));
    return ServicioMapper.toDto(servicioRepository.save(servicio));
  }
}
