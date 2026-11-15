package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.RegistrarVehiculoCommand;
import com.lavadero.scheduling.application.dto.VehiculoDto;
import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Agrega un vehículo a "Mis vehículos". La placa se normaliza (ABC-123 → ABC123) antes de comprobar
 * que el cliente no tenga ya uno activo con la misma; el índice único parcial de V22 respalda la
 * regla si dos peticiones llegan a la vez (y {@code GlobalExceptionHandler} lo traduce a 409).
 */
@Service
public class RegistrarVehiculoUseCase implements UseCase<RegistrarVehiculoCommand, VehiculoDto> {

  private final VehiculoRepository vehiculoRepository;

  public RegistrarVehiculoUseCase(VehiculoRepository vehiculoRepository) {
    this.vehiculoRepository = vehiculoRepository;
  }

  @Override
  @Transactional
  public VehiculoDto execute(RegistrarVehiculoCommand input) {
    Placa placa = Placa.de(input.placa());
    if (vehiculoRepository.existeActivoConPlaca(input.clienteId(), placa)) {
      throw new ValidationException("Ya tienes un vehículo con la placa %s".formatted(placa));
    }
    Vehiculo vehiculo =
        Vehiculo.nuevo(
            TenantContext.requerido(),
            input.clienteId(),
            placa,
            input.tipo(),
            input.marca(),
            input.color());
    return VehiculoMapper.toDto(vehiculoRepository.save(vehiculo));
  }
}
