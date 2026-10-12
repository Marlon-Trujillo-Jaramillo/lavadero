package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.identity.infrastructure.security.JwtAuthenticatedPrincipal;
import com.lavadero.scheduling.application.command.CrearIncidenciaCommand;
import com.lavadero.scheduling.application.usecase.CrearIncidenciaUseCase;
import com.lavadero.scheduling.application.usecase.ListarMisIncidenciasUseCase;
import com.lavadero.scheduling.interfaces.rest.dto.CrearIncidenciaRequest;
import com.lavadero.scheduling.interfaces.rest.dto.IncidenciaResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Incidencias reportadas por el staff — ver docs/specs/006-checklist-incidencias.md. Sin vista de
 * admin en esta fase: el empleado ve únicamente lo que él mismo reportó (mismo criterio de
 * exposición mínima que {@code ReservaController#misReservas}).
 */
@RestController
public class IncidenciaController {

  private final CrearIncidenciaUseCase crearIncidenciaUseCase;
  private final ListarMisIncidenciasUseCase listarMisIncidenciasUseCase;

  public IncidenciaController(
      CrearIncidenciaUseCase crearIncidenciaUseCase,
      ListarMisIncidenciasUseCase listarMisIncidenciasUseCase) {
    this.crearIncidenciaUseCase = crearIncidenciaUseCase;
    this.listarMisIncidenciasUseCase = listarMisIncidenciasUseCase;
  }

  @PostMapping("/api/v1/incidencias")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResponseEntity<IncidenciaResponse> crear(
      @AuthenticationPrincipal JwtAuthenticatedPrincipal principal,
      @Valid @RequestBody CrearIncidenciaRequest request) {
    var creada =
        crearIncidenciaUseCase.execute(
            new CrearIncidenciaCommand(
                principal.usuarioId(),
                request.sucursalId(),
                request.reservaId(),
                request.categoria(),
                request.descripcion()));
    return ResponseEntity.created(URI.create("/api/v1/incidencias/" + creada.id()))
        .body(IncidenciaResponse.from(creada));
  }

  @GetMapping("/api/v1/incidencias/mias")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<IncidenciaResponse> misIncidencias(
      @AuthenticationPrincipal JwtAuthenticatedPrincipal principal) {
    return listarMisIncidenciasUseCase.execute(principal.usuarioId()).stream()
        .map(IncidenciaResponse::from)
        .toList();
  }
}
