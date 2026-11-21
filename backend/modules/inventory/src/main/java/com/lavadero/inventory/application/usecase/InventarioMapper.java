package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.dto.InsumoConStockDto;
import com.lavadero.inventory.application.dto.MovimientoDto;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.MovimientoInventario;
import com.lavadero.inventory.domain.model.StockInsumo;

final class InventarioMapper {

  private InventarioMapper() {}

  static InsumoConStockDto toDto(Insumo i, StockInsumo s) {
    return new InsumoConStockDto(
        i.getId(),
        i.getNombre(),
        i.getUnidad().name(),
        i.getCostoUnitario(),
        i.getMoneda().getCurrencyCode(),
        s.sucursalId(),
        s.cantidad(),
        s.minimo(),
        s.bajoMinimo());
  }

  static MovimientoDto toDto(MovimientoInventario m) {
    return new MovimientoDto(
        m.id(), m.tipo().name(), m.cantidad(), m.saldo(), m.reservaId(), m.nota(), m.creadoEn());
  }
}
