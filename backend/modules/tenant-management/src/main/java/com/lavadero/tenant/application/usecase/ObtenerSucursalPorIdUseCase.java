package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Punto de entrada público para que OTROS módulos (p. ej. scheduling) resuelvan una sucursal por
 * id.
 */
@Service
public class ObtenerSucursalPorIdUseCase implements UseCase<UUID, SucursalDto> {

  private final SucursalRepository sucursalRepository;

  public ObtenerSucursalPorIdUseCase(SucursalRepository sucursalRepository) {
    this.sucursalRepository = sucursalRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public SucursalDto execute(UUID sucursalId) {
    Sucursal sucursal =
        sucursalRepository
            .findById(sucursalId)
            .orElseThrow(() -> NotFoundException.de("Sucursal", sucursalId));
    return new SucursalDto(
        sucursal.getId(),
        sucursal.getNombre(),
        sucursal.getDireccion(),
        sucursal.getCapacidadSimultanea());
  }
}
