package com.lavadero.scheduling.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ReservaTest {

  private static final Money PRECIO = Money.cop(new BigDecimal("15000"));

  private Reserva nueva() {
    return Reserva.nueva(
        UUID.randomUUID(),
        UUID.randomUUID(),
        UUID.randomUUID(),
        UUID.randomUUID(),
        Instant.now(),
        20,
        PRECIO);
  }

  @Test
  void nueva_reserva_empieza_pendiente() {
    assertThat(nueva().getEstado()).isEqualTo(ReservaEstado.PENDIENTE);
  }

  @Test
  void iniciar_pasa_de_pendiente_a_en_progreso() {
    Reserva reserva = nueva();
    reserva.iniciar();
    assertThat(reserva.getEstado()).isEqualTo(ReservaEstado.EN_PROGRESO);
  }

  @Test
  void no_se_puede_iniciar_una_reserva_que_no_esta_pendiente() {
    Reserva reserva = nueva();
    reserva.iniciar();
    assertThatThrownBy(reserva::iniciar).isInstanceOf(IllegalStateException.class);
  }

  @Test
  void completar_pasa_de_en_progreso_a_completada() {
    Reserva reserva = nueva();
    reserva.iniciar();
    reserva.completar();
    assertThat(reserva.getEstado()).isEqualTo(ReservaEstado.COMPLETADA);
  }

  @Test
  void no_se_puede_completar_una_reserva_que_no_esta_en_progreso() {
    Reserva reserva = nueva();
    assertThatThrownBy(reserva::completar).isInstanceOf(IllegalStateException.class);
  }

  @Test
  void cancelar_solo_es_valido_desde_pendiente() {
    Reserva reserva = nueva();
    reserva.iniciar();
    assertThatThrownBy(reserva::cancelar).isInstanceOf(IllegalStateException.class);
  }

  @Test
  void cancelar_desde_pendiente_funciona() {
    Reserva reserva = nueva();
    reserva.cancelar();
    assertThat(reserva.getEstado()).isEqualTo(ReservaEstado.CANCELADA);
  }

  @Test
  void fecha_hora_fin_se_calcula_desde_la_duracion() {
    Instant inicio = Instant.parse("2026-08-01T10:00:00Z");
    Reserva reserva =
        Reserva.nueva(
            UUID.randomUUID(),
            UUID.randomUUID(),
            UUID.randomUUID(),
            UUID.randomUUID(),
            inicio,
            30,
            PRECIO);
    assertThat(reserva.getFechaHoraFin()).isEqualTo(Instant.parse("2026-08-01T10:30:00Z"));
  }

  @Test
  void esta_activa_es_verdadero_solo_en_pendiente_y_en_progreso() {
    Reserva reserva = nueva();
    assertThat(reserva.estaActiva()).isTrue();
    reserva.iniciar();
    assertThat(reserva.estaActiva()).isTrue();
    reserva.completar();
    assertThat(reserva.estaActiva()).isFalse();
  }
}
