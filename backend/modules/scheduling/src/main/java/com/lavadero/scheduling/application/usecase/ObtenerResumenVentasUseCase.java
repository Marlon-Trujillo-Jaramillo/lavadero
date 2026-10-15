package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ResumenVentasQuery;
import com.lavadero.scheduling.application.dto.ResumenVentasDto;
import com.lavadero.scheduling.application.dto.ServicioPopularDto;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import java.time.Duration;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resumen de ventas (reservas COMPLETADA) del tenant actual en un rango — vista de
 * dashboard/reportes.
 */
@Service
public class ObtenerResumenVentasUseCase implements UseCase<ResumenVentasQuery, ResumenVentasDto> {

  /** Un año (bisiesto incluido): más que eso es un volcado, no un reporte de dashboard. */
  static final Duration RANGO_MAXIMO = Duration.ofDays(366);

  private final ReservaRepository reservaRepository;

  public ObtenerResumenVentasUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public ResumenVentasDto execute(ResumenVentasQuery input) {
    if (!input.desde().isBefore(input.hasta())) {
      throw new ValidationException("'desde' no puede ser posterior a 'hasta'");
    }
    if (Duration.between(input.desde(), input.hasta()).compareTo(RANGO_MAXIMO) > 0) {
      throw new ValidationException("El rango del reporte no puede superar 366 días");
    }
    UUID sucursalId = input.alcance().resolverFiltro(input.sucursalId());
    ResumenVentas resumen =
        reservaRepository.obtenerResumenVentas(input.desde(), input.hasta(), sucursalId);
    return new ResumenVentasDto(
        resumen.ingresosTotales().monto(),
        resumen.ingresosTotales().moneda().getCurrencyCode(),
        resumen.totalReservasCompletadas(),
        resumen.serviciosMasPedidos().stream()
            .map(sp -> new ServicioPopularDto(sp.servicioId(), sp.nombreServicio(), sp.cantidad()))
            .toList());
  }
}
