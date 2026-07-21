package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ResumenVentasQuery;
import com.lavadero.scheduling.application.dto.ResumenVentasDto;
import com.lavadero.scheduling.application.dto.ServicioPopularDto;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resumen de ventas (reservas COMPLETADA) del tenant actual en un rango — vista de
 * dashboard/reportes.
 */
@Service
public class ObtenerResumenVentasUseCase implements UseCase<ResumenVentasQuery, ResumenVentasDto> {

  private final ReservaRepository reservaRepository;

  public ObtenerResumenVentasUseCase(ReservaRepository reservaRepository) {
    this.reservaRepository = reservaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public ResumenVentasDto execute(ResumenVentasQuery input) {
    ResumenVentas resumen = reservaRepository.obtenerResumenVentas(input.desde(), input.hasta());
    return new ResumenVentasDto(
        resumen.ingresosTotales().monto(),
        resumen.ingresosTotales().moneda().getCurrencyCode(),
        resumen.totalReservasCompletadas(),
        resumen.serviciosMasPedidos().stream()
            .map(sp -> new ServicioPopularDto(sp.servicioId(), sp.nombreServicio(), sp.cantidad()))
            .toList());
  }
}
