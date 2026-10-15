package com.lavadero.scheduling.interfaces.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.shared.application.exception.ValidationException;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class FechasConsultaTest {

  @Test
  void convierteElDiaALimitesUtc() {
    LocalDate dia = LocalDate.of(2026, 10, 12);

    assertThat(FechasConsulta.inicioDelDia(dia, "fecha"))
        .isEqualTo(Instant.parse("2026-10-12T00:00:00Z"));
    assertThat(FechasConsulta.finDelDia(dia, "fecha"))
        .isEqualTo(Instant.parse("2026-10-13T00:00:00Z"));
  }

  @Test
  void unAnioExtremoEsUnErrorDelClienteNoUn500() {
    assertThatThrownBy(() -> FechasConsulta.finDelDia(LocalDate.MAX, "hasta"))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("'hasta'");
    assertThatThrownBy(() -> FechasConsulta.inicioDelDia(LocalDate.of(1, 1, 1), "desde"))
        .isInstanceOf(ValidationException.class);
  }
}
