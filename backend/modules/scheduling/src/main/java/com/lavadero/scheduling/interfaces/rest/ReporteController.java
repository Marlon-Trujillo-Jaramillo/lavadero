package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.ResumenVentasQuery;
import com.lavadero.scheduling.application.usecase.ObtenerResumenVentasUseCase;
import com.lavadero.scheduling.interfaces.rest.dto.ResumenVentasResponse;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.security.access.prepost.PreAuthorize;
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
   * (ISO date, inclusive/exclusive respectivamente — el día `hasta` completo no se incluye).
   */
  @GetMapping("/api/v1/agenda/reportes/resumen")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResumenVentasResponse resumen(
      @RequestParam LocalDate desde, @RequestParam LocalDate hasta) {
    var desdeInstant = desde.atStartOfDay(ZoneOffset.UTC).toInstant();
    var hastaInstant = hasta.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
    return ResumenVentasResponse.from(
        obtenerResumenVentasUseCase.execute(new ResumenVentasQuery(desdeInstant, hastaInstant)));
  }
}
