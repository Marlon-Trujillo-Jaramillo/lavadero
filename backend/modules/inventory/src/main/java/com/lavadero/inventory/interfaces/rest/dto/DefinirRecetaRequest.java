package com.lavadero.inventory.interfaces.rest.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record DefinirRecetaRequest(
    @NotNull(message = "La receta es obligatoria") @Size(max = 20) @Valid List<Linea> lineas) {

  public record Linea(
      @NotNull(message = "Falta el insumo") UUID insumoId,
      @NotNull(message = "Falta la cantidad")
          @Digits(integer = 9, fraction = 3, message = "Cantidad inválida")
          BigDecimal cantidad) {}
}
