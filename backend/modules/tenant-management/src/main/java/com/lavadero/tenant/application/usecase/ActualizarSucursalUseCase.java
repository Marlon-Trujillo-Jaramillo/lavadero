package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.tenant.application.command.ActualizarSucursalCommand;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ActualizarSucursalUseCase implements UseCase<ActualizarSucursalCommand, SucursalDto> {

  private final SucursalRepository sucursalRepository;

  public ActualizarSucursalUseCase(SucursalRepository sucursalRepository) {
    this.sucursalRepository = sucursalRepository;
  }

  @Override
  @Transactional
  public SucursalDto execute(ActualizarSucursalCommand input) {
    Sucursal sucursal =
        sucursalRepository
            .findById(input.sucursalId())
            .orElseThrow(() -> NotFoundException.de("Sucursal", input.sucursalId()));
    sucursal.actualizarDetalles(input.nombre(), input.direccion(), input.capacidadSimultanea());
    Sucursal guardada = sucursalRepository.save(sucursal);
    return new SucursalDto(
        guardada.getId(),
        guardada.getNombre(),
        guardada.getDireccion(),
        guardada.getCapacidadSimultanea());
  }
}
