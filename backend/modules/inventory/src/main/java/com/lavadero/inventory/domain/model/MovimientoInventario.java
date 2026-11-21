package com.lavadero.inventory.domain.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Una línea del kardex: cada cambio de stock con su motivo y el saldo resultante. Se agrega, nunca
 * se edita. {@code cantidad} lleva signo (+ entra, − sale).
 */
public record MovimientoInventario(
    UUID id,
    UUID insumoId,
    UUID sucursalId,
    TipoMovimiento tipo,
    BigDecimal cantidad,
    BigDecimal saldo,
    UUID reservaId,
    String nota,
    Instant creadoEn) {

  static final int NOTA_MAX = 120;

  public MovimientoInventario {
    Objects.requireNonNull(id, "id no puede ser nulo");
    Objects.requireNonNull(insumoId, "insumoId no puede ser nulo");
    Objects.requireNonNull(sucursalId, "sucursalId no puede ser nulo");
    Objects.requireNonNull(tipo, "tipo no puede ser nulo");
    Objects.requireNonNull(cantidad, "cantidad no puede ser nula");
    Objects.requireNonNull(saldo, "saldo no puede ser nulo");
    Objects.requireNonNull(creadoEn, "creadoEn no puede ser nulo");
    if (tipo == TipoMovimiento.CONSUMO && reservaId == null) {
      throw new IllegalArgumentException("Un consumo siempre viene de una reserva");
    }
    if (nota != null) {
      nota = nota.strip();
      if (nota.isEmpty()) {
        nota = null;
      } else if (nota.length() > NOTA_MAX) {
        throw new IllegalArgumentException("La nota admite hasta " + NOTA_MAX + " caracteres");
      }
    }
  }

  public static MovimientoInventario de(
      UUID insumoId,
      UUID sucursalId,
      TipoMovimiento tipo,
      BigDecimal cantidad,
      BigDecimal saldo,
      UUID reservaId,
      String nota,
      Instant ahora) {
    return new MovimientoInventario(
        UUID.randomUUID(), insumoId, sucursalId, tipo, cantidad, saldo, reservaId, nota, ahora);
  }
}
