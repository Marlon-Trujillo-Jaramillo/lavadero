package com.lavadero.catalog.application.usecase;

import com.lavadero.catalog.application.command.ActualizarServicioCommand;
import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.domain.Money;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ActualizarServicioUseCase implements UseCase<ActualizarServicioCommand, ServicioDto> {

  private final ServicioRepository servicioRepository;

  public ActualizarServicioUseCase(ServicioRepository servicioRepository) {
    this.servicioRepository = servicioRepository;
  }

  @Override
  @Transactional
  public ServicioDto execute(ActualizarServicioCommand input) {
    Servicio servicio =
        servicioRepository
            .findById(input.servicioId())
            .orElseThrow(() -> NotFoundException.de("Servicio", input.servicioId()));
    servicio.actualizarDetalles(
        input.nombre(), input.descripcion(), input.duracionEstimadaMinutos());
    servicio.actualizarPrecio(Money.cop(input.precio()));
    return ServicioMapper.toDto(servicioRepository.save(servicio));
  }
}
