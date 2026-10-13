package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.command.CrearEmpleadoCommand;
import com.lavadero.identity.application.dto.EmpleadoDto;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Da de alta un empleado (staff) del tenant actual — antes de esto, la única forma de tener un
 * usuario EMPLEADO era una inserción manual en la base de datos (ver spec de auditoría técnica/
 * negocio 2026-08-18). Sin sistema de notificaciones todavía (ver Fase 3 de esa misma auditoría):
 * el admin fija la contraseña inicial y se la comunica al empleado fuera de banda.
 */
@Service
public class CrearEmpleadoUseCase implements UseCase<CrearEmpleadoCommand, EmpleadoDto> {

  private final UsuarioRepository usuarioRepository;
  private final PasswordEncoder passwordEncoder;
  private final ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase;

  public CrearEmpleadoUseCase(
      UsuarioRepository usuarioRepository,
      PasswordEncoder passwordEncoder,
      ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase) {
    this.usuarioRepository = usuarioRepository;
    this.passwordEncoder = passwordEncoder;
    this.obtenerSucursalPorIdUseCase = obtenerSucursalPorIdUseCase;
  }

  @Override
  @Transactional
  public EmpleadoDto execute(CrearEmpleadoCommand input) {
    var tenantId = TenantContext.requerido();
    String email = input.email().toLowerCase();

    if (usuarioRepository.existsByEmailAndTenantId(email, tenantId)) {
      throw new ValidationException("Ya existe un usuario con ese email en este tenant");
    }

    // La FK a sucursal no pasa por RLS: sin esta lectura (que sí la aplica, 404 si es de otro
    // tenant) el empleado podría quedar asignado a una sucursal ajena.
    if (input.sucursalId() != null) {
      obtenerSucursalPorIdUseCase.execute(input.sucursalId());
    }

    String passwordHash = passwordEncoder.encode(input.password());
    Usuario empleado =
        Usuario.empleado(tenantId, email, input.nombre(), passwordHash, input.sucursalId());
    Usuario guardado = usuarioRepository.save(empleado);

    return new EmpleadoDto(
        guardado.getId(),
        guardado.getEmail(),
        guardado.getNombre(),
        guardado.getSucursalId().orElse(null),
        guardado.getEstado().name());
  }
}
