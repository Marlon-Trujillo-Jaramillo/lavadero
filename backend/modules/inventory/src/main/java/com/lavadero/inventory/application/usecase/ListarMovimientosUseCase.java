package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.command.InventarioQuery;
import com.lavadero.inventory.application.dto.MovimientoDto;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Kardex de un insumo en una sucursal: los últimos {@value #LIMITE} movimientos. */
@Service
public class ListarMovimientosUseCase implements UseCase<InventarioQuery, List<MovimientoDto>> {

  static final int LIMITE = 50;

  private final MovimientoRepository movimientoRepository;

  public ListarMovimientosUseCase(MovimientoRepository movimientoRepository) {
    this.movimientoRepository = movimientoRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<MovimientoDto> execute(InventarioQuery input) {
    UUID sucursalId = SucursalDeInventario.resolver(input.alcance(), input.sucursalId());
    return movimientoRepository.recientes(input.insumoId(), sucursalId, LIMITE).stream()
        .map(InventarioMapper::toDto)
        .toList();
  }
}
