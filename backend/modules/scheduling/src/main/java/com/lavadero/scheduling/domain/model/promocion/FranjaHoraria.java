package com.lavadero.scheduling.domain.model.promocion;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.EnumSet;
import java.util.Objects;
import java.util.Set;

/**
 * Días de la semana y franja {@code [desde, hasta)} en hora local del lavadero, p. ej. "martes y
 * miércoles de 8:00 a 11:00". Cuenta la hora de inicio de la reserva.
 */
public record FranjaHoraria(Set<DayOfWeek> dias, LocalTime desde, LocalTime hasta) {

  public FranjaHoraria {
    Objects.requireNonNull(dias, "dias no puede ser nulo");
    Objects.requireNonNull(desde, "desde no puede ser nulo");
    Objects.requireNonNull(hasta, "hasta no puede ser nulo");
    if (dias.isEmpty()) {
      throw new IllegalArgumentException("Elige al menos un día de la semana");
    }
    if (!desde.isBefore(hasta)) {
      throw new IllegalArgumentException("La hora de inicio debe ser anterior a la de fin");
    }
    dias = Set.copyOf(EnumSet.copyOf(dias));
  }

  public boolean contiene(LocalDateTime inicioLocal) {
    LocalTime hora = inicioLocal.toLocalTime();
    return dias.contains(inicioLocal.getDayOfWeek())
        && !hora.isBefore(desde)
        && hora.isBefore(hasta);
  }

  /** Lunes = 1, martes = 2, miércoles = 4 ... domingo = 64 (columna {@code dias_semana}). */
  public int mascara() {
    int mascara = 0;
    for (DayOfWeek dia : dias) {
      mascara |= 1 << (dia.getValue() - 1);
    }
    return mascara;
  }

  public static Set<DayOfWeek> diasDeMascara(int mascara) {
    Set<DayOfWeek> dias = EnumSet.noneOf(DayOfWeek.class);
    for (DayOfWeek dia : DayOfWeek.values()) {
      if ((mascara & (1 << (dia.getValue() - 1))) != 0) {
        dias.add(dia);
      }
    }
    return dias;
  }
}
