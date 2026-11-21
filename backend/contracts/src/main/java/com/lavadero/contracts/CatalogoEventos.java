package com.lavadero.contracts;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import java.util.List;
import java.util.Optional;

/**
 * Los eventos de integración que existen, con su nombre estable (el que se guarda en el outbox y
 * viaja como header) y su tópico de Kafka. El nombre, no el de la clase Java: renombrar o mover una
 * clase no puede romper los mensajes que ya están en el outbox o en Kafka.
 */
public final class CatalogoEventos {

  public record Tipo(String nombre, String topico, Class<? extends EventoIntegracion> clase) {}

  public static final Tipo RESERVA_COMPLETADA =
      new Tipo("reserva.completada", "lavadero.reserva.completada", ReservaCompletadaEvent.class);

  private static final List<Tipo> TIPOS = List.of(RESERVA_COMPLETADA);

  private CatalogoEventos() {}

  public static List<Tipo> todos() {
    return TIPOS;
  }

  public static Optional<Tipo> porNombre(String nombre) {
    return TIPOS.stream().filter(t -> t.nombre().equals(nombre)).findFirst();
  }

  public static Tipo de(EventoIntegracion evento) {
    return TIPOS.stream()
        .filter(t -> t.clase().equals(evento.getClass()))
        .findFirst()
        .orElseThrow(
            () ->
                new IllegalArgumentException(
                    evento.getClass().getSimpleName() + " no está en CatalogoEventos"));
  }
}
