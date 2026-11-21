package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.command.CambioStockCommand;
import com.lavadero.inventory.domain.model.Cantidades;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.security.TenantContext;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Umbral de alerta de reposición de un insumo en una sucursal (0 = sin alerta). */
@Service
public class FijarMinimoUseCase implements UseCase<CambioStockCommand, Void> {

  private final InsumoRepository insumoRepository;
  private final StockRepository stockRepository;

  public FijarMinimoUseCase(InsumoRepository insumoRepository, StockRepository stockRepository) {
    this.insumoRepository = insumoRepository;
    this.stockRepository = stockRepository;
  }

  @Override
  @Transactional
  public Void execute(CambioStockCommand input) {
    UUID sucursalId = SucursalDeInventario.resolver(input.alcance(), input.sucursalId());
    insumoRepository
        .findById(input.insumoId())
        .orElseThrow(() -> NotFoundException.de("Insumo", input.insumoId()));
    stockRepository.fijarMinimo(
        TenantContext.requerido(),
        input.insumoId(),
        sucursalId,
        Cantidades.noNegativa(input.cantidad(), "El mínimo"));
    return null;
  }
}
