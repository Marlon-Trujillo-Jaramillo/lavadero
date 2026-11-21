package com.lavadero.inventory.domain.repository;

import com.lavadero.inventory.domain.model.MovimientoInventario;
import java.util.List;
import java.util.UUID;

public interface MovimientoRepository {

  void registrar(UUID tenantId, MovimientoInventario movimiento);

  /** Más recientes primero. */
  List<MovimientoInventario> recientes(UUID insumoId, UUID sucursalId, int limite);

  boolean consumoRegistrado(UUID reservaId);
}
