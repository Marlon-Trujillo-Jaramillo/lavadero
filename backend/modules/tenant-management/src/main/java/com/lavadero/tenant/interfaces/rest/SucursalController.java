package com.lavadero.tenant.interfaces.rest;

import com.lavadero.tenant.application.command.ActualizarSucursalCommand;
import com.lavadero.tenant.application.command.CrearSucursalCommand;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.application.usecase.ActualizarSucursalUseCase;
import com.lavadero.tenant.application.usecase.CrearSucursalUseCase;
import com.lavadero.tenant.application.usecase.ListarSucursalesUseCase;
import com.lavadero.tenant.interfaces.rest.dto.ActualizarSucursalRequest;
import com.lavadero.tenant.interfaces.rest.dto.CrearSucursalRequest;
import com.lavadero.tenant.interfaces.rest.dto.SucursalResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SucursalController {

  private final ListarSucursalesUseCase listarSucursalesUseCase;
  private final CrearSucursalUseCase crearSucursalUseCase;
  private final ActualizarSucursalUseCase actualizarSucursalUseCase;

  public SucursalController(
      ListarSucursalesUseCase listarSucursalesUseCase,
      CrearSucursalUseCase crearSucursalUseCase,
      ActualizarSucursalUseCase actualizarSucursalUseCase) {
    this.listarSucursalesUseCase = listarSucursalesUseCase;
    this.crearSucursalUseCase = crearSucursalUseCase;
    this.actualizarSucursalUseCase = actualizarSucursalUseCase;
  }

  /**
   * Cualquier usuario autenticado del tenant puede listar sus sucursales (elegir dónde reservar,
   * ver la agenda).
   */
  @GetMapping("/api/v1/sucursales")
  public List<SucursalResponse> listar() {
    return listarSucursalesUseCase.execute(null).stream().map(SucursalResponse::from).toList();
  }

  /**
   * Alta de una sucursal adicional. Solo {@code ADMIN_TENANT}: abrir una sede nueva es una decisión
   * a nivel de todo el tenant, no de una sucursal existente ({@code ADMIN_SUCURSAL} está acotado a
   * la suya).
   */
  @PostMapping("/api/v1/sucursales")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<SucursalResponse> crear(@Valid @RequestBody CrearSucursalRequest request) {
    SucursalDto creada =
        crearSucursalUseCase.execute(
            new CrearSucursalCommand(
                request.nombre(), request.direccion(), request.capacidadSimultanea()));
    return ResponseEntity.created(URI.create("/api/v1/sucursales/" + creada.id()))
        .body(SucursalResponse.from(creada));
  }

  @PutMapping("/api/v1/sucursales/{id}")
  @PreAuthorize("hasRole('ADMIN_TENANT') or hasSucursal(#id)")
  public SucursalResponse actualizar(
      @PathVariable UUID id, @Valid @RequestBody ActualizarSucursalRequest request) {
    SucursalDto actualizada =
        actualizarSucursalUseCase.execute(
            new ActualizarSucursalCommand(
                id, request.nombre(), request.direccion(), request.capacidadSimultanea()));
    return SucursalResponse.from(actualizada);
  }
}
