package com.lavadero.inventory.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.model.UnidadMedida;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Currency;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ListarCostosPorServicioUseCaseTest {

  private static final Currency COP = Currency.getInstance("COP");

  @Test
  void sumaElCostoDeLaRecetaYCalculaElMargen() {
    Insumo shampoo =
        Insumo.nuevo(
            UUID.randomUUID(),
            "Shampoo",
            UnidadMedida.ML,
            new BigDecimal("12.5"),
            COP,
            Instant.now());
    Insumo cera =
        Insumo.nuevo(
            UUID.randomUUID(), "Cera", UnidadMedida.G, new BigDecimal("80"), COP, Instant.now());
    ServicioDto full =
        new ServicioDto(
            UUID.randomUUID(), "Lavado full", null, 45, new BigDecimal("45000"), "COP", true);

    var costo =
        ListarCostosPorServicioUseCase.costo(
            full,
            List.of(
                new LineaReceta(shampoo.getId(), new BigDecimal("40")),
                new LineaReceta(cera.getId(), new BigDecimal("25"))),
            Map.of(shampoo.getId(), shampoo, cera.getId(), cera));

    assertThat(costo.costoInsumos()).isEqualByComparingTo("2500"); // 500 + 2000
    assertThat(costo.margen()).isEqualByComparingTo("42500");
    assertThat(costo.margenPorcentaje()).isEqualTo(94);
    assertThat(costo.lineas()).extracting(l -> l.insumo()).containsExactly("Shampoo", "Cera");
  }

  @Test
  void sinRecetaElCostoEsCeroYUnServicioGratisNoDivideEntreCero() {
    ServicioDto gratis =
        new ServicioDto(UUID.randomUUID(), "Cortesía", null, 10, BigDecimal.ZERO, "COP", true);

    var costo = ListarCostosPorServicioUseCase.costo(gratis, List.of(), Map.of());

    assertThat(costo.costoInsumos()).isEqualByComparingTo("0");
    assertThat(costo.margenPorcentaje()).isNull();
  }
}
