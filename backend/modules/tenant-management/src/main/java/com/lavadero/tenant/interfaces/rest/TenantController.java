package com.lavadero.tenant.interfaces.rest;

import com.lavadero.tenant.application.command.CrearTenantCommand;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.BuscarTenantsActivosUseCase;
import com.lavadero.tenant.application.usecase.CrearTenantUseCase;
import com.lavadero.tenant.interfaces.rest.dto.CrearTenantRequest;
import com.lavadero.tenant.interfaces.rest.dto.TenantPublicoResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TenantController {

  private final BuscarTenantsActivosUseCase buscarTenantsActivosUseCase;
  private final CrearTenantUseCase crearTenantUseCase;

  public TenantController(
      BuscarTenantsActivosUseCase buscarTenantsActivosUseCase,
      CrearTenantUseCase crearTenantUseCase) {
    this.buscarTenantsActivosUseCase = buscarTenantsActivosUseCase;
    this.crearTenantUseCase = crearTenantUseCase;
  }

  /**
   * Público: lista/busca tenants activos por nombre, para la pantalla de selección de lavadero en
   * la app. No requiere autenticación (ver lista blanca en {@code TenantResolutionFilter},
   * identity-access).
   */
  @GetMapping("/api/v1/tenants")
  public List<TenantPublicoResponse> buscar(@RequestParam(defaultValue = "") String query) {
    return buscarTenantsActivosUseCase.execute(query).stream()
        .map(TenantPublicoResponse::from)
        .toList();
  }

  /** Onboarding de un tenant nuevo. Restringido a la plataforma (SUPER_ADMIN). */
  @PostMapping("/api/v1/tenants")
  @PreAuthorize("hasRole('SUPER_ADMIN')")
  public ResponseEntity<TenantPublicoResponse> crear(
      @Valid @RequestBody CrearTenantRequest request) {
    TenantResumenDto creado =
        crearTenantUseCase.execute(
            new CrearTenantCommand(
                request.nombre(), request.nit(), request.slug(), request.subscriptionPlanId()));
    return ResponseEntity.created(URI.create("/api/v1/tenants/" + creado.id()))
        .body(TenantPublicoResponse.from(creado));
  }
}
