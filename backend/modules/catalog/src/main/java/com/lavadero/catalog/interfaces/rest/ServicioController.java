package com.lavadero.catalog.interfaces.rest;

import com.lavadero.catalog.application.command.ActualizarServicioCommand;
import com.lavadero.catalog.application.command.CambiarEstadoServicioCommand;
import com.lavadero.catalog.application.command.CrearServicioCommand;
import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ActualizarServicioUseCase;
import com.lavadero.catalog.application.usecase.BuscarServiciosActivosUseCase;
import com.lavadero.catalog.application.usecase.CambiarEstadoServicioUseCase;
import com.lavadero.catalog.application.usecase.CrearServicioUseCase;
import com.lavadero.catalog.application.usecase.ListarServiciosUseCase;
import com.lavadero.catalog.interfaces.rest.dto.ActualizarServicioRequest;
import com.lavadero.catalog.interfaces.rest.dto.CambiarEstadoServicioRequest;
import com.lavadero.catalog.interfaces.rest.dto.CrearServicioRequest;
import com.lavadero.catalog.interfaces.rest.dto.ServicioResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ServicioController {

  private final ListarServiciosUseCase listarServiciosUseCase;
  private final BuscarServiciosActivosUseCase buscarServiciosActivosUseCase;
  private final CrearServicioUseCase crearServicioUseCase;
  private final ActualizarServicioUseCase actualizarServicioUseCase;
  private final CambiarEstadoServicioUseCase cambiarEstadoServicioUseCase;

  public ServicioController(
      ListarServiciosUseCase listarServiciosUseCase,
      BuscarServiciosActivosUseCase buscarServiciosActivosUseCase,
      CrearServicioUseCase crearServicioUseCase,
      ActualizarServicioUseCase actualizarServicioUseCase,
      CambiarEstadoServicioUseCase cambiarEstadoServicioUseCase) {
    this.listarServiciosUseCase = listarServiciosUseCase;
    this.buscarServiciosActivosUseCase = buscarServiciosActivosUseCase;
    this.crearServicioUseCase = crearServicioUseCase;
    this.actualizarServicioUseCase = actualizarServicioUseCase;
    this.cambiarEstadoServicioUseCase = cambiarEstadoServicioUseCase;
  }

  /**
   * Administración: todos los servicios del tenant actual, activos e inactivos. El catálogo y los
   * precios son de todo el tenant (no por sucursal), así que ADMIN_SUCURSAL puede leerlo pero solo
   * ADMIN_TENANT lo modifica.
   */
  @GetMapping("/api/v1/catalogo/servicios")
  @PreAuthorize("hasAnyRole('ADMIN_TENANT','ADMIN_SUCURSAL')")
  public List<ServicioResponse> listarTodos() {
    return listarServiciosUseCase.execute(null).stream().map(ServicioResponse::from).toList();
  }

  /** Cliente/empleado: solo servicios activos, para elegir al reservar. */
  @GetMapping("/api/v1/catalogo/servicios/activos")
  public List<ServicioResponse> listarActivos() {
    return buscarServiciosActivosUseCase.execute(null).stream()
        .map(ServicioResponse::from)
        .toList();
  }

  @PostMapping("/api/v1/catalogo/servicios")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<ServicioResponse> crear(@Valid @RequestBody CrearServicioRequest request) {
    ServicioDto creado =
        crearServicioUseCase.execute(
            new CrearServicioCommand(
                request.nombre(),
                request.descripcion(),
                request.duracionEstimadaMinutos(),
                request.precio()));
    return ResponseEntity.created(URI.create("/api/v1/catalogo/servicios/" + creado.id()))
        .body(ServicioResponse.from(creado));
  }

  @PutMapping("/api/v1/catalogo/servicios/{id}")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ServicioResponse actualizar(
      @PathVariable UUID id, @Valid @RequestBody ActualizarServicioRequest request) {
    ServicioDto actualizado =
        actualizarServicioUseCase.execute(
            new ActualizarServicioCommand(
                id,
                request.nombre(),
                request.descripcion(),
                request.duracionEstimadaMinutos(),
                request.precio()));
    return ServicioResponse.from(actualizado);
  }

  @PatchMapping("/api/v1/catalogo/servicios/{id}/estado")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ServicioResponse cambiarEstado(
      @PathVariable UUID id, @RequestBody CambiarEstadoServicioRequest request) {
    ServicioDto actualizado =
        cambiarEstadoServicioUseCase.execute(
            new CambiarEstadoServicioCommand(id, request.activo()));
    return ServicioResponse.from(actualizado);
  }
}
