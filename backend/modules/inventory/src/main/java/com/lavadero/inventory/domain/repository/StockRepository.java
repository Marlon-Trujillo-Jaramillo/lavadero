package com.lavadero.inventory.domain.repository;

import com.lavadero.inventory.domain.model.StockInsumo;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Stock por insumo y sucursal. Los cambios son sentencias atómicas en la base de datos (suma con
 * {@code UPSERT ... RETURNING}), no "leer, sumar en Java y guardar": dos lavados que terminan a la
 * vez no pueden perder un descuento.
 */
public interface StockRepository {

  /** Suma {@code delta} (puede ser negativo) y devuelve el saldo resultante. */
  BigDecimal sumar(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal delta);

  /**
   * Fija la cantidad (conteo físico) y devuelve la que había antes. Bloquea la fila durante la
   * transacción para que un consumo simultáneo no se pierda entre la lectura y la escritura.
   */
  BigDecimal fijar(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal cantidad);

  void fijarMinimo(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal minimo);

  List<StockInsumo> deSucursal(UUID sucursalId);
}
