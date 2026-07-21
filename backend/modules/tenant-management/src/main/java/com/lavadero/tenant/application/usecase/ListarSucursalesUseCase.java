package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lista las sucursales del tenant actual — usado por el flujo de reserva (elegir dónde) y la agenda
 * de empleado.
 */
@Service
public class ListarSucursalesUseCase implements UseCase<Void, List<SucursalDto>> {

  private final SucursalRepository sucursalRepository;

  public ListarSucursalesUseCase(SucursalRepository sucursalRepository) {
    this.sucursalRepository = sucursalRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<SucursalDto> execute(Void input) {
    return sucursalRepository.findAllDelTenantActual().stream()
        .map(
            s ->
                new SucursalDto(
                    s.getId(), s.getNombre(), s.getDireccion(), s.getCapacidadSimultanea()))
        .toList();
  }
}
