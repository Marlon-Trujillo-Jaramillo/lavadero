package com.lavadero.scheduling.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class IncidenciaTest {

  @Test
  void nueva_incidencia_puede_no_tener_reserva_asociada() {
    Incidencia incidencia =
        Incidencia.nueva(
            UUID.randomUUID(),
            UUID.randomUUID(),
            null,
            UUID.randomUUID(),
            IncidenciaCategoria.FALTANTE_INSUMO,
            "Falta shampoo");
    assertThat(incidencia.getReservaId()).isEmpty();
  }

  @Test
  void nueva_incidencia_conserva_la_reserva_asociada_si_se_da() {
    UUID reservaId = UUID.randomUUID();
    Incidencia incidencia =
        Incidencia.nueva(
            UUID.randomUUID(),
            UUID.randomUUID(),
            reservaId,
            UUID.randomUUID(),
            IncidenciaCategoria.DANIO_VEHICULO,
            "Rayón en la puerta");
    assertThat(incidencia.getReservaId()).contains(reservaId);
  }

  @Test
  void descripcion_vacia_es_invalida() {
    assertThatThrownBy(
            () ->
                Incidencia.nueva(
                    UUID.randomUUID(),
                    UUID.randomUUID(),
                    null,
                    UUID.randomUUID(),
                    IncidenciaCategoria.OTRO,
                    "  "))
        .isInstanceOf(IllegalArgumentException.class);
  }
}
