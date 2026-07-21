package com.lavadero.scheduling.domain.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class DisponibilidadServiceTest {

  private static final Money PRECIO = Money.cop(new BigDecimal("15000"));
  private static final UUID TENANT = UUID.randomUUID();
  private static final UUID SUCURSAL = UUID.randomUUID();

  private Reserva reservaEn(Instant inicio, int duracionMinutos) {
    return Reserva.nueva(
        TENANT, SUCURSAL, UUID.randomUUID(), UUID.randomUUID(), inicio, duracionMinutos, PRECIO);
  }

  @Test
  void hay_cupo_si_no_hay_reservas_previas() {
    Instant inicio = Instant.parse("2026-08-01T10:00:00Z");
    Instant fin = Instant.parse("2026-08-01T10:20:00Z");

    boolean hayCupo = DisponibilidadService.hayCupo(1, List.of(), inicio, fin);

    assertThat(hayCupo).isTrue();
  }

  @Test
  void no_hay_cupo_si_el_horario_se_solapa_y_la_capacidad_ya_esta_llena() {
    Reserva existente = reservaEn(Instant.parse("2026-08-01T10:00:00Z"), 20);
    Instant nuevaInicio = Instant.parse("2026-08-01T10:10:00Z");
    Instant nuevaFin = Instant.parse("2026-08-01T10:30:00Z");

    boolean hayCupo = DisponibilidadService.hayCupo(1, List.of(existente), nuevaInicio, nuevaFin);

    assertThat(hayCupo).isFalse();
  }

  @Test
  void hay_cupo_si_el_horario_no_se_solapa_aunque_la_capacidad_sea_uno() {
    Reserva existente = reservaEn(Instant.parse("2026-08-01T10:00:00Z"), 20); // 10:00-10:20
    Instant nuevaInicio =
        Instant.parse("2026-08-01T10:20:00Z"); // empieza justo cuando termina la anterior
    Instant nuevaFin = Instant.parse("2026-08-01T10:40:00Z");

    boolean hayCupo = DisponibilidadService.hayCupo(1, List.of(existente), nuevaInicio, nuevaFin);

    assertThat(hayCupo).isTrue();
  }

  @Test
  void hay_cupo_si_la_capacidad_alcanza_para_las_reservas_solapadas_existentes() {
    Reserva existente = reservaEn(Instant.parse("2026-08-01T10:00:00Z"), 20);
    Instant nuevaInicio = Instant.parse("2026-08-01T10:05:00Z");
    Instant nuevaFin = Instant.parse("2026-08-01T10:25:00Z");

    boolean hayCupo = DisponibilidadService.hayCupo(2, List.of(existente), nuevaInicio, nuevaFin);

    assertThat(hayCupo).isTrue();
  }
}
