package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.dto.EmpleadoDto;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.security.AlcanceSucursal;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lista los empleados del tenant actual, para la pantalla de administración de staff. Un
 * ADMIN_SUCURSAL solo ve los de su sucursal.
 */
@Service
public class ListarEmpleadosUseCase implements UseCase<AlcanceSucursal, List<EmpleadoDto>> {

  private final UsuarioRepository usuarioRepository;

  public ListarEmpleadosUseCase(UsuarioRepository usuarioRepository) {
    this.usuarioRepository = usuarioRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<EmpleadoDto> execute(AlcanceSucursal alcance) {
    return usuarioRepository.findEmpleadosDelTenantActual(alcance.resolverFiltro(null)).stream()
        .map(
            u ->
                new EmpleadoDto(
                    u.getId(),
                    u.getEmail(),
                    u.getNombre(),
                    u.getSucursalId().orElse(null),
                    u.getEstado().name()))
        .toList();
  }
}
