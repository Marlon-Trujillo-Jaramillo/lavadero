package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.ArchivarVehiculoCommand;
import com.lavadero.scheduling.application.command.RegistrarVehiculoCommand;
import com.lavadero.scheduling.application.usecase.ArchivarVehiculoUseCase;
import com.lavadero.scheduling.application.usecase.ListarMisVehiculosUseCase;
import com.lavadero.scheduling.application.usecase.RegistrarVehiculoUseCase;
import com.lavadero.scheduling.interfaces.rest.dto.RegistrarVehiculoRequest;
import com.lavadero.scheduling.interfaces.rest.dto.VehiculoResponse;
import com.lavadero.shared.security.PrincipalAutenticado;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * "Mis vehículos" del cliente — ver docs/specs/009-mis-vehiculos.md. Siempre acotado al cliente
 * autenticado: el {@code clienteId} sale del token, nunca del body ni de la URL.
 */
@RestController
public class VehiculoController {

  private final ListarMisVehiculosUseCase listarMisVehiculosUseCase;
  private final RegistrarVehiculoUseCase registrarVehiculoUseCase;
  private final ArchivarVehiculoUseCase archivarVehiculoUseCase;

  public VehiculoController(
      ListarMisVehiculosUseCase listarMisVehiculosUseCase,
      RegistrarVehiculoUseCase registrarVehiculoUseCase,
      ArchivarVehiculoUseCase archivarVehiculoUseCase) {
    this.listarMisVehiculosUseCase = listarMisVehiculosUseCase;
    this.registrarVehiculoUseCase = registrarVehiculoUseCase;
    this.archivarVehiculoUseCase = archivarVehiculoUseCase;
  }

  @GetMapping("/api/v1/vehiculos/mios")
  @PreAuthorize("hasRole('CLIENTE')")
  public List<VehiculoResponse> misVehiculos(
      @AuthenticationPrincipal PrincipalAutenticado principal) {
    return listarMisVehiculosUseCase.execute(principal.usuarioId()).stream()
        .map(VehiculoResponse::from)
        .toList();
  }

  @PostMapping("/api/v1/vehiculos")
  @PreAuthorize("hasRole('CLIENTE')")
  public ResponseEntity<VehiculoResponse> registrar(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @Valid @RequestBody RegistrarVehiculoRequest request) {
    var creado =
        registrarVehiculoUseCase.execute(
            new RegistrarVehiculoCommand(
                principal.usuarioId(),
                request.placa(),
                request.tipo(),
                request.marca(),
                request.color()));
    return ResponseEntity.created(URI.create("/api/v1/vehiculos/" + creado.id()))
        .body(VehiculoResponse.from(creado));
  }

  @DeleteMapping("/api/v1/vehiculos/{id}")
  @PreAuthorize("hasRole('CLIENTE')")
  public ResponseEntity<Void> archivar(
      @AuthenticationPrincipal PrincipalAutenticado principal, @PathVariable UUID id) {
    archivarVehiculoUseCase.execute(new ArchivarVehiculoCommand(principal.usuarioId(), id));
    return ResponseEntity.noContent().build();
  }
}
