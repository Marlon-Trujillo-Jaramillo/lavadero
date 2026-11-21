package com.lavadero.inventory.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Currency;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class InventarioDominioTest {

  private static final Currency COP = Currency.getInstance("COP");

  @Test
  void elCostoPorUnidadAdmiteFraccionesDePeso() {
    Insumo shampoo =
        Insumo.nuevo(
            UUID.randomUUID(),
            " Shampoo ",
            UnidadMedida.ML,
            new BigDecimal("12.5"),
            COP,
            Instant.now());

    assertThat(shampoo.getNombre()).isEqualTo("Shampoo");
    assertThat(shampoo.costoDe(new BigDecimal("40"))).isEqualByComparingTo("500");
    assertThatThrownBy(
            () ->
                Insumo.nuevo(
                    UUID.randomUUID(),
                    "X",
                    UnidadMedida.G,
                    new BigDecimal("0.00001"),
                    COP,
                    Instant.now()))
        .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(
            () ->
                Insumo.nuevo(
                    UUID.randomUUID(),
                    "X",
                    UnidadMedida.G,
                    new BigDecimal("-1"),
                    COP,
                    Instant.now()))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void lasCantidadesSonPositivasConHastaTresDecimales() {
    assertThat(Cantidades.positiva(new BigDecimal("0.125"), "x")).isEqualByComparingTo("0.125");
    assertThatThrownBy(() -> Cantidades.positiva(BigDecimal.ZERO, "x"))
        .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> Cantidades.positiva(new BigDecimal("1.0001"), "x"))
        .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new LineaReceta(UUID.randomUUID(), new BigDecimal("-5")))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void bajoMinimoSoloSiHayUnMinimoDefinido() {
    UUID insumo = UUID.randomUUID();
    UUID sucursal = UUID.randomUUID();

    assertThat(new StockInsumo(insumo, sucursal, BigDecimal.ZERO, BigDecimal.ZERO).bajoMinimo())
        .isFalse();
    assertThat(
            new StockInsumo(insumo, sucursal, new BigDecimal("500"), new BigDecimal("500"))
                .bajoMinimo())
        .isTrue();
    assertThat(
            new StockInsumo(insumo, sucursal, new BigDecimal("-20"), new BigDecimal("100"))
                .bajoMinimo())
        .isTrue();
  }

  @Test
  void unConsumoSinReservaNoExiste() {
    assertThatThrownBy(
            () ->
                MovimientoInventario.de(
                    UUID.randomUUID(),
                    UUID.randomUUID(),
                    TipoMovimiento.CONSUMO,
                    new BigDecimal("-40"),
                    BigDecimal.TEN,
                    null,
                    null,
                    Instant.now()))
        .isInstanceOf(IllegalArgumentException.class);
    assertThat(
            MovimientoInventario.de(
                    UUID.randomUUID(),
                    UUID.randomUUID(),
                    TipoMovimiento.ENTRADA,
                    BigDecimal.TEN,
                    BigDecimal.TEN,
                    null,
                    "   ",
                    Instant.now())
                .nota())
        .isNull();
  }
}
