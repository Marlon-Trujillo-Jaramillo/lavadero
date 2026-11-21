package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.command.InventarioQuery;
import com.lavadero.inventory.application.dto.InsumoConStockDto;
import com.lavadero.inventory.domain.model.StockInsumo;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.StockRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Insumos activos con su stock en una sucursal; los bajo mínimo primero. Dos consultas. */
@Service
public class ListarInventarioUseCase implements UseCase<InventarioQuery, List<InsumoConStockDto>> {

  private final InsumoRepository insumoRepository;
  private final StockRepository stockRepository;

  public ListarInventarioUseCase(
      InsumoRepository insumoRepository, StockRepository stockRepository) {
    this.insumoRepository = insumoRepository;
    this.stockRepository = stockRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<InsumoConStockDto> execute(InventarioQuery input) {
    UUID sucursalId = SucursalDeInventario.resolver(input.alcance(), input.sucursalId());
    var stock =
        stockRepository.deSucursal(sucursalId).stream()
            .collect(Collectors.toMap(StockInsumo::insumoId, Function.identity()));
    return insumoRepository.listarActivos().stream()
        .map(
            i ->
                InventarioMapper.toDto(
                    i, stock.getOrDefault(i.getId(), StockInsumo.vacio(i.getId(), sucursalId))))
        .sorted((a, b) -> Boolean.compare(b.bajoMinimo(), a.bajoMinimo()))
        .toList();
  }
}
