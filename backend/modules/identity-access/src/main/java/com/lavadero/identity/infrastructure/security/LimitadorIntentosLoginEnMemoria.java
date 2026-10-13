package com.lavadero.identity.infrastructure.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.lavadero.identity.application.port.LimitadorIntentosLogin;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import org.springframework.stereotype.Component;

/**
 * {@link LimitadorIntentosLogin} en memoria: {@value #MAX_FALLOS} intentos no exitosos dentro de
 * {@link #VENTANA} bloquean la cuenta durante {@link #BLOQUEO}. Cada intento se cuenta de forma
 * atómica (lock por cuenta) antes de verificar la contraseña; el exitoso se descuenta borrando el
 * historial.
 *
 * <p>Límite residual: el intento que alcanza el umbral todavía se evalúa (si acierta, desbloquea);
 * a lo sumo {@value #MAX_FALLOS} contraseñas se prueban por ventana y por instancia.
 *
 * <p>LIMITACIÓN conocida (igual que {@code RateLimitFilter}): el estado vive en este proceso. Con
 * más de una instancia del backend cada una cuenta por separado (el umbral efectivo se multiplica
 * por el número de instancias) y un reinicio borra los bloqueos. Si se escala horizontalmente, esto
 * debe migrar a Redis.
 *
 * <p>Trade-off aceptado: bloquear por cuenta permite que un tercero bloquee temporalmente a un
 * usuario legítimo fallando a propósito; es el precio de frenar la fuerza bruta distribuida.
 */
@Component
public class LimitadorIntentosLoginEnMemoria implements LimitadorIntentosLogin {

  static final int MAX_FALLOS = 5;
  static final Duration VENTANA = Duration.ofMinutes(15);
  static final Duration BLOQUEO = Duration.ofMinutes(15);

  private final Clock reloj;
  private final Cache<String, Intentos> intentos =
      Caffeine.newBuilder().expireAfterAccess(VENTANA.plus(BLOQUEO)).maximumSize(100_000).build();

  public LimitadorIntentosLoginEnMemoria(Clock reloj) {
    this.reloj = reloj;
  }

  @Override
  public boolean registrarIntento(String claveCuenta) {
    return intentos.get(claveCuenta, k -> new Intentos()).intentar(reloj.instant());
  }

  @Override
  public void registrarExito(String claveCuenta) {
    intentos.invalidate(claveCuenta);
  }

  private static final class Intentos {
    private final Deque<Instant> fallos = new ArrayDeque<>();
    private Instant bloqueadaHasta = Instant.MIN;

    synchronized boolean intentar(Instant ahora) {
      if (ahora.isBefore(bloqueadaHasta)) {
        return false;
      }
      Instant inicioVentana = ahora.minus(VENTANA);
      while (!fallos.isEmpty() && !fallos.peekFirst().isAfter(inicioVentana)) {
        fallos.pollFirst();
      }
      fallos.addLast(ahora);
      if (fallos.size() >= MAX_FALLOS) {
        bloqueadaHasta = ahora.plus(BLOQUEO);
        fallos.clear();
      }
      return true;
    }
  }
}
