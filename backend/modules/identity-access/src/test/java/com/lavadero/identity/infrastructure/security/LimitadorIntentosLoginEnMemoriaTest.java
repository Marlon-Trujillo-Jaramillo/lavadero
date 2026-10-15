package com.lavadero.identity.infrastructure.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

class LimitadorIntentosLoginEnMemoriaTest {

  private static final String CUENTA = "tenant-1|ana@lavadero.com";

  private final RelojManual reloj = new RelojManual(Instant.parse("2026-10-12T10:00:00Z"));
  private final LimitadorIntentosLoginEnMemoria limitador =
      new LimitadorIntentosLoginEnMemoria(reloj);

  @Test
  void cincoIntentosFallidosEnLaVentanaBloqueanLaCuentaQuinceMinutos() {
    assertThat(intentar(5)).as("los 5 primeros se evalúan").isTrue();
    assertThat(limitador.registrarIntento(CUENTA)).isFalse();
    assertThat(limitador.registrarIntento("tenant-1|otra@lavadero.com"))
        .as("el bloqueo es por cuenta")
        .isTrue();

    reloj.avanzar(Duration.ofMinutes(14));
    assertThat(limitador.registrarIntento(CUENTA)).isFalse();
    reloj.avanzar(Duration.ofMinutes(2));
    assertThat(limitador.registrarIntento(CUENTA)).isTrue();
  }

  @Test
  void losIntentosFueraDeLaVentanaNoCuentan() {
    intentar(4);
    reloj.avanzar(Duration.ofMinutes(16));
    intentar(4);

    assertThat(limitador.registrarIntento(CUENTA)).isTrue();
  }

  @Test
  void unLoginCorrectoReiniciaElConteo() {
    intentar(4);
    limitador.registrarExito(CUENTA);
    intentar(4);

    assertThat(limitador.registrarIntento(CUENTA)).isTrue();
  }

  @Test
  void intentosConcurrentesNoEsquivanElUmbral() throws Exception {
    int hilos = 50;
    var permitidos = new AtomicInteger();
    var inicio = new CountDownLatch(1);
    try (var ejecutor = Executors.newFixedThreadPool(hilos)) {
      for (int i = 0; i < hilos; i++) {
        ejecutor.submit(
            () -> {
              inicio.await();
              if (limitador.registrarIntento(CUENTA)) {
                permitidos.incrementAndGet();
              }
              return null;
            });
      }
      inicio.countDown();
    }

    assertThat(permitidos.get()).isEqualTo(LimitadorIntentosLoginEnMemoria.MAX_FALLOS);
  }

  private boolean intentar(int veces) {
    boolean todosPermitidos = true;
    for (int i = 0; i < veces; i++) {
      todosPermitidos &= limitador.registrarIntento(CUENTA);
    }
    return todosPermitidos;
  }

  static final class RelojManual extends Clock {
    private Instant ahora;

    RelojManual(Instant inicio) {
      this.ahora = inicio;
    }

    void avanzar(Duration duracion) {
      ahora = ahora.plus(duracion);
    }

    @Override
    public ZoneId getZone() {
      return ZoneOffset.UTC;
    }

    @Override
    public Clock withZone(ZoneId zone) {
      return this;
    }

    @Override
    public Instant instant() {
      return ahora;
    }
  }
}
