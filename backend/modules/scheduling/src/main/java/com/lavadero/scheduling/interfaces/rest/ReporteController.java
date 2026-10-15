package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.ResumenVentasQuery;
import com.lavadero.scheduling.application.usecase.ObtenerResumenVentasUseCase;
import com.lavadero.scheduling.interfaces.rest.dto.ResumenVentasResponse;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReporteController {

  private final ObtenerResumenVentasUseCase obtenerResumenVentasUseCase;

  public ReporteController(ObtenerResumenVentasUseCase obtenerResumenVentasUseCase) {
    this.obtenerResumenVentasUseCase = obtenerResumenVentasUseCase;
  }

  /**
   * Resumen de ventas (reservas COMPLETADA) del tenant actual entre {@code desde} y {@code hasta}
   * (ISO date, ambos inclusive: el día `hasta` completo se incluye). Rango máximo 366 días y {@code
   * desde <= hasta} (400 si no). {@code sucursalId} opcional filtra por sucursal; un ADMIN_SUCURSAL
   * siempre ve solo la suya.
   */
  @GetMapping("/api/v1/agenda/reportes/resumen")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResumenVentasResponse resumen(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam LocalDate desde,
      @RequestParam LocalDate hasta,
      @RequestParam(required = false) UUID sucursalId) {
    var desdeInstant = FechasConsulta.inicioDelDia(desde, "desde");
    var hastaInstant = FechasConsulta.finDelDia(hasta, "hasta");
    return ResumenVentasResponse.from(
        obtenerResumenVentasUseCase.execute(
            new ResumenVentasQuery(
                desdeInstant, hastaInstant, sucursalId, AlcanceSucursal.de(principal))));
  }
}
