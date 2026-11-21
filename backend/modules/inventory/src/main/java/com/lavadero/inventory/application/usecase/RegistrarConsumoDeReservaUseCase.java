package com.lavadero.inventory.application.usecase;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.model.MovimientoInventario;
import com.lavadero.inventory.domain.model.TipoMovimiento;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import com.lavadero.shared.application.UseCase;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Descuenta de la sucursal los insumos de la receta del servicio que se completó. Es idempotente:
 * si la reserva ya descontó (evento repetido), no hace nada; el índice único de la tabla respalda
 * esa regla. El stock puede quedar negativo: terminar un lavado nunca falla por el inventario.
 */
@Service
public class RegistrarConsumoDeReservaUseCase implements UseCase<ReservaCompletadaEvent, Integer> {

  private final RecetaRepository recetaRepository;
  private final StockRepository stockRepository;
  private final MovimientoRepository movimientoRepository;

  public RegistrarConsumoDeReservaUseCase(
      RecetaRepository recetaRepository,
      StockRepository stockRepository,
      MovimientoRepository movimientoRepository) {
    this.recetaRepository = recetaRepository;
    this.stockRepository = stockRepository;
    this.movimientoRepository = movimientoRepository;
  }

  /** Devuelve cuántos insumos descontó. */
  @Override
  @Transactional
  public Integer execute(ReservaCompletadaEvent evento) {
    if (movimientoRepository.consumoRegistrado(evento.reservaId())) {
      return 0;
    }
    List<LineaReceta> receta = recetaRepository.deServicio(evento.servicioId());
    for (LineaReceta linea : receta) {
      BigDecimal saldo =
          stockRepository.sumar(
              evento.tenantId(), linea.insumoId(), evento.sucursalId(), linea.cantidad().negate());
      movimientoRepository.registrar(
          evento.tenantId(),
          MovimientoInventario.de(
              linea.insumoId(),
              evento.sucursalId(),
              TipoMovimiento.CONSUMO,
              linea.cantidad().negate(),
              saldo,
              evento.reservaId(),
              null,
              evento.occurredOn()));
    }
    return receta.size();
  }
}
