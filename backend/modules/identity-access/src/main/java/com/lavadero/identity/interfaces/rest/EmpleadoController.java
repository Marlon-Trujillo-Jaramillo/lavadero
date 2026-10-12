package com.lavadero.identity.interfaces.rest;

import com.lavadero.identity.application.command.CrearEmpleadoCommand;
import com.lavadero.identity.application.dto.EmpleadoDto;
import com.lavadero.identity.application.usecase.CrearEmpleadoUseCase;
import com.lavadero.identity.application.usecase.ListarEmpleadosUseCase;
import com.lavadero.identity.interfaces.rest.dto.CrearEmpleadoRequest;
import com.lavadero.identity.interfaces.rest.dto.EmpleadoResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Administración de staff (rol EMPLEADO) del tenant actual. Antes de esto, la única forma de tener
 * un empleado en el sistema era una fila insertada a mano en la base de datos.
 */
@RestController
public class EmpleadoController {

  private final ListarEmpleadosUseCase listarEmpleadosUseCase;
  private final CrearEmpleadoUseCase crearEmpleadoUseCase;

  public EmpleadoController(
      ListarEmpleadosUseCase listarEmpleadosUseCase, CrearEmpleadoUseCase crearEmpleadoUseCase) {
    this.listarEmpleadosUseCase = listarEmpleadosUseCase;
    this.crearEmpleadoUseCase = crearEmpleadoUseCase;
  }

  @GetMapping("/api/v1/empleados")
  @PreAuthorize("hasAnyRole('ADMIN_TENANT','ADMIN_SUCURSAL')")
  public List<EmpleadoResponse> listar() {
    return listarEmpleadosUseCase.execute(null).stream().map(EmpleadoResponse::from).toList();
  }

  @PostMapping("/api/v1/empleados")
  @PreAuthorize("hasRole('ADMIN_TENANT') or hasSucursal(#request.sucursalId())")
  public ResponseEntity<EmpleadoResponse> crear(@Valid @RequestBody CrearEmpleadoRequest request) {
    EmpleadoDto creado =
        crearEmpleadoUseCase.execute(
            new CrearEmpleadoCommand(
                request.email(), request.password(), request.nombre(), request.sucursalId()));
    return ResponseEntity.created(URI.create("/api/v1/empleados/" + creado.id()))
        .body(EmpleadoResponse.from(creado));
  }
}
