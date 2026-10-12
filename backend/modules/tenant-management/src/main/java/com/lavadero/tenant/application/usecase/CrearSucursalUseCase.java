package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.CrearSucursalCommand;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Da de alta una sucursal adicional del tenant actual (resuelto de {@link TenantContext}) — antes
 * de esto, la única forma de que un tenant tuviera más de una sucursal era una inserción manual en
 * la base de datos (ver spec de auditoría técnica/negocio 2026-08-18).
 */
@Service
public class CrearSucursalUseCase implements UseCase<CrearSucursalCommand, SucursalDto> {

  private final SucursalRepository sucursalRepository;

  public CrearSucursalUseCase(SucursalRepository sucursalRepository) {
    this.sucursalRepository = sucursalRepository;
  }

  @Override
  @Transactional
  public SucursalDto execute(CrearSucursalCommand input) {
    Sucursal sucursal =
        Sucursal.nueva(
            TenantContext.requerido(),
            input.nombre(),
            input.direccion(),
            input.capacidadSimultanea());
    Sucursal guardada = sucursalRepository.save(sucursal);
    return new SucursalDto(
        guardada.getId(),
        guardada.getNombre(),
        guardada.getDireccion(),
        guardada.getCapacidadSimultanea());
  }
}
