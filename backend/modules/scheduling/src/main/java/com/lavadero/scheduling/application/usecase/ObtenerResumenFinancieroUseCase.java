package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ResumenFinancieroQuery;
import com.lavadero.scheduling.application.dto.ResumenFinancieroDto;
import com.lavadero.scheduling.domain.repository.GastoRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ingresos (reservas COMPLETADA) menos gastos del periodo = utilidad. Los días {@code desde} y
 * {@code hasta} se interpretan en UTC, igual que el resumen de ventas de reportes.
 */
@Service
public class ObtenerResumenFinancieroUseCase
    implements UseCase<ResumenFinancieroQuery, ResumenFinancieroDto> {

  private final ReservaRepository reservaRepository;
  private final GastoRepository gastoRepository;

  public ObtenerResumenFinancieroUseCase(
      ReservaRepository reservaRepository, GastoRepository gastoRepository) {
    this.reservaRepository = reservaRepository;
    this.gastoRepository = gastoRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public ResumenFinancieroDto execute(ResumenFinancieroQuery input) {
    RangoReporte.validar(input.desde(), input.hasta());
    UUID sucursalId = input.alcance().resolverFiltro(input.sucursalId());
    Instant desde = input.desde().atStartOfDay(ZoneOffset.UTC).toInstant();
    Instant hasta = input.hasta().plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
    Money ingresos =
        reservaRepository.obtenerResumenVentas(desde, hasta, sucursalId).ingresosTotales();
    Money gastos = gastoRepository.sumar(input.desde(), input.hasta(), sucursalId);
    BigDecimal utilidad = ingresos.monto().subtract(gastos.monto());
    return new ResumenFinancieroDto(
        ingresos.monto(), gastos.monto(), utilidad, ingresos.moneda().getCurrencyCode());
  }
}
