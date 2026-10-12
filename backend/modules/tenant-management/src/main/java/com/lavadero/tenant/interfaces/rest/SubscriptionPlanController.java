package com.lavadero.tenant.interfaces.rest;

import com.lavadero.tenant.application.command.ActualizarSubscriptionPlanCommand;
import com.lavadero.tenant.application.command.CrearSubscriptionPlanCommand;
import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import com.lavadero.tenant.application.usecase.ActualizarSubscriptionPlanUseCase;
import com.lavadero.tenant.application.usecase.CrearSubscriptionPlanUseCase;
import com.lavadero.tenant.application.usecase.ListarSubscriptionPlanesUseCase;
import com.lavadero.tenant.interfaces.rest.dto.ActualizarSubscriptionPlanRequest;
import com.lavadero.tenant.interfaces.rest.dto.CrearSubscriptionPlanRequest;
import com.lavadero.tenant.interfaces.rest.dto.SubscriptionPlanResponse;
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

/**
 * Gestión del catálogo de planes de suscripción de la plataforma. Dato de plataforma (no de un
 * tenant), restringido a SUPER_ADMIN — mismo criterio que {@code TenantController#crear}.
 */
@RestController
public class SubscriptionPlanController {

  private final ListarSubscriptionPlanesUseCase listarSubscriptionPlanesUseCase;
  private final CrearSubscriptionPlanUseCase crearSubscriptionPlanUseCase;
  private final ActualizarSubscriptionPlanUseCase actualizarSubscriptionPlanUseCase;

  public SubscriptionPlanController(
      ListarSubscriptionPlanesUseCase listarSubscriptionPlanesUseCase,
      CrearSubscriptionPlanUseCase crearSubscriptionPlanUseCase,
      ActualizarSubscriptionPlanUseCase actualizarSubscriptionPlanUseCase) {
    this.listarSubscriptionPlanesUseCase = listarSubscriptionPlanesUseCase;
    this.crearSubscriptionPlanUseCase = crearSubscriptionPlanUseCase;
    this.actualizarSubscriptionPlanUseCase = actualizarSubscriptionPlanUseCase;
  }

  @GetMapping("/api/v1/plataforma/planes")
  @PreAuthorize("hasRole('SUPER_ADMIN')")
  public List<SubscriptionPlanResponse> listar() {
    return listarSubscriptionPlanesUseCase.execute(null).stream()
        .map(SubscriptionPlanResponse::from)
        .toList();
  }

  @PostMapping("/api/v1/plataforma/planes")
  @PreAuthorize("hasRole('SUPER_ADMIN')")
  public ResponseEntity<SubscriptionPlanResponse> crear(
      @Valid @RequestBody CrearSubscriptionPlanRequest request) {
    SubscriptionPlanDto creado =
        crearSubscriptionPlanUseCase.execute(
            new CrearSubscriptionPlanCommand(
                request.nombre(),
                request.precio(),
                request.maxSucursales(),
                request.maxEmpleados(),
                request.features()));
    return ResponseEntity.created(URI.create("/api/v1/plataforma/planes/" + creado.id()))
        .body(SubscriptionPlanResponse.from(creado));
  }

  @PutMapping("/api/v1/plataforma/planes/{id}")
  @PreAuthorize("hasRole('SUPER_ADMIN')")
  public SubscriptionPlanResponse actualizar(
      @PathVariable UUID id, @Valid @RequestBody ActualizarSubscriptionPlanRequest request) {
    SubscriptionPlanDto actualizado =
        actualizarSubscriptionPlanUseCase.execute(
            new ActualizarSubscriptionPlanCommand(
                id,
                request.nombre(),
                request.precio(),
                request.maxSucursales(),
                request.maxEmpleados(),
                request.features()));
    return SubscriptionPlanResponse.from(actualizado);
  }
}
