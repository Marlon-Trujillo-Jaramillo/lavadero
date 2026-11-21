package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.command.CambioStockCommand;
import com.lavadero.inventory.application.dto.MovimientoDto;
import com.lavadero.inventory.domain.model.Cantidades;
import com.lavadero.inventory.domain.model.MovimientoInventario;
import com.lavadero.inventory.domain.model.TipoMovimiento;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.security.TenantContext;
import java.math.BigDecimal;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Conteo físico: el stock pasa a ser lo contado y el kardex guarda la diferencia (lo que se perdió,
 * se regaló o no se registró). Si lo contado coincide, igual queda la línea: "se contó y cuadró".
 */
@Service
public class AjustarStockUseCase implements UseCase<CambioStockCommand, MovimientoDto> {

  private final InsumoRepository insumoRepository;
  private final StockRepository stockRepository;
  private final MovimientoRepository movimientoRepository;
  private final Clock reloj;

  public AjustarStockUseCase(
      InsumoRepository insumoRepository,
      StockRepository stockRepository,
      MovimientoRepository movimientoRepository,
      Clock reloj) {
    this.insumoRepository = insumoRepository;
    this.stockRepository = stockRepository;
    this.movimientoRepository = movimientoRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public MovimientoDto execute(CambioStockCommand input) {
    UUID sucursalId = SucursalDeInventario.resolver(input.alcance(), input.sucursalId());
    insumoRepository
        .findById(input.insumoId())
        .orElseThrow(() -> NotFoundException.de("Insumo", input.insumoId()));
    BigDecimal contada = Cantidades.noNegativa(input.cantidad(), "La cantidad contada");
    UUID tenantId = TenantContext.requerido();

    BigDecimal anterior = stockRepository.fijar(tenantId, input.insumoId(), sucursalId, contada);
    MovimientoInventario movimiento =
        MovimientoInventario.de(
            input.insumoId(),
            sucursalId,
            TipoMovimiento.AJUSTE,
            contada.subtract(anterior),
            contada,
            null,
            input.nota(),
            reloj.instant());
    movimientoRepository.registrar(tenantId, movimiento);
    return InventarioMapper.toDto(movimiento);
  }
}
