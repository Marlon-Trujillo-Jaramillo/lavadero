package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.ListarGastosQuery;
import com.lavadero.scheduling.application.command.RegistrarGastoCommand;
import com.lavadero.scheduling.application.command.ResumenFinancieroQuery;
import com.lavadero.scheduling.application.usecase.ListarGastosUseCase;
import com.lavadero.scheduling.application.usecase.ObtenerResumenFinancieroUseCase;
import com.lavadero.scheduling.application.usecase.RegistrarGastoUseCase;
import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import com.lavadero.scheduling.interfaces.rest.dto.GastoResponse;
import com.lavadero.scheduling.interfaces.rest.dto.RegistrarGastoRequest;
import com.lavadero.scheduling.interfaces.rest.dto.ResumenFinancieroResponse;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Gastos operativos y resumen financiero (ingresos − gastos = utilidad). El dueño y el admin de
 * sucursal registran y consultan; el alcance de sucursal se aplica en los casos de uso. Ver
 * docs/specs/014-gastos.md.
 */
@RestController
public class GastoController {

  private final RegistrarGastoUseCase registrarGastoUseCase;
  private final ListarGastosUseCase listarGastosUseCase;
  private final ObtenerResumenFinancieroUseCase obtenerResumenFinancieroUseCase;

  public GastoController(
      RegistrarGastoUseCase registrarGastoUseCase,
      ListarGastosUseCase listarGastosUseCase,
      ObtenerResumenFinancieroUseCase obtenerResumenFinancieroUseCase) {
    this.registrarGastoUseCase = registrarGastoUseCase;
    this.listarGastosUseCase = listarGastosUseCase;
    this.obtenerResumenFinancieroUseCase = obtenerResumenFinancieroUseCase;
  }

  @PostMapping("/api/v1/gastos")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResponseEntity<GastoResponse> registrar(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @Valid @RequestBody RegistrarGastoRequest r) {
    var dto =
        registrarGastoUseCase.execute(
            new RegistrarGastoCommand(
                r.sucursalId(),
                r.fecha(),
                ParametrosEnum.requerido(CategoriaGasto.class, r.categoria(), "categoria"),
                r.descripcion(),
                r.monto(),
                r.moneda(),
                AlcanceSucursal.de(principal)));
    return ResponseEntity.created(URI.create("/api/v1/gastos/" + dto.id()))
        .body(GastoResponse.from(dto));
  }

  @GetMapping("/api/v1/gastos")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<GastoResponse> listar(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
      @RequestParam(required = false) UUID sucursalId) {
    return listarGastosUseCase
        .execute(new ListarGastosQuery(desde, hasta, sucursalId, AlcanceSucursal.de(principal)))
        .stream()
        .map(GastoResponse::from)
        .toList();
  }

  @GetMapping("/api/v1/finanzas/resumen")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResumenFinancieroResponse resumen(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
      @RequestParam(required = false) UUID sucursalId) {
    return ResumenFinancieroResponse.from(
        obtenerResumenFinancieroUseCase.execute(
            new ResumenFinancieroQuery(desde, hasta, sucursalId, AlcanceSucursal.de(principal))));
  }
}
