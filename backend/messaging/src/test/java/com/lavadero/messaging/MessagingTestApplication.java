package com.lavadero.messaging;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.shared.security.TenantContext;
import java.time.Clock;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/** Aplicación mínima de test, con un manejador que anota lo que recibe y puede fallar a pedido. */
@SpringBootApplication
public class MessagingTestApplication {

  @Bean
  Clock reloj() {
    return Clock.systemUTC();
  }

  @Bean
  ManejadorDePrueba manejadorDePrueba() {
    return new ManejadorDePrueba();
  }

  /** Anota cada evento con el tenant que tenía el contexto al recibirlo. */
  public static class ManejadorDePrueba implements ManejadorEvento<ReservaCompletadaEvent> {

    public record Recibido(ReservaCompletadaEvent evento, UUID tenantEnContexto) {}

    public final List<Recibido> recibidos = new CopyOnWriteArrayList<>();
    public final Set<UUID> reservasQueFallan = ConcurrentHashMap.newKeySet();

    @Override
    public Class<ReservaCompletadaEvent> tipo() {
      return ReservaCompletadaEvent.class;
    }

    @Override
    public void manejar(ReservaCompletadaEvent evento) {
      if (reservasQueFallan.contains(evento.reservaId())) {
        throw new IllegalStateException("Falla simulada para " + evento.reservaId());
      }
      recibidos.add(new Recibido(evento, TenantContext.get().orElse(null)));
    }

    public void limpiar() {
      recibidos.clear();
      reservasQueFallan.clear();
    }
  }
}
