package com.lavadero.scheduling.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.scheduling.application.command.CotizarReservaQuery;
import com.lavadero.scheduling.application.dto.CotizacionDto;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.domain.Money;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Precio que pagaría el cliente por un servicio a una hora, con la mejor promoción que aplique. Es
 * lo mismo que calcula {@link CrearReservaUseCase}, sin crear nada: la app lo muestra antes de
 * confirmar.
 */
@Service
public class CotizarReservaUseCase implements UseCase<CotizarReservaQuery, CotizacionDto> {

  private final ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase;
  private final ResolvedorPromociones resolvedorPromociones;

  CotizarReservaUseCase(
      ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase,
      ResolvedorPromociones resolvedorPromociones) {
    this.obtenerServicioPorIdUseCase = obtenerServicioPorIdUseCase;
    this.resolvedorPromociones = resolvedorPromociones;
  }

  @Override
  @Transactional(readOnly = true)
  public CotizacionDto execute(CotizarReservaQuery input) {
    ServicioDto servicio = obtenerServicioPorIdUseCase.execute(input.servicioId());
    Money lista = Money.de(servicio.precio(), servicio.moneda());
    return PromocionMapper.toDto(
        resolvedorPromociones.cotizar(lista, input.fechaHoraInicio(), input.codigoCupon()));
  }
}
