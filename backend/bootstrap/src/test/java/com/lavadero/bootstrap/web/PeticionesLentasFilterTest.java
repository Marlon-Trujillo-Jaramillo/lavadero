package com.lavadero.bootstrap.web;

import static org.assertj.core.api.Assertions.assertThat;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class PeticionesLentasFilterTest {

  private final AtomicLong ahoraNanos = new AtomicLong();
  private final ListAppender<ILoggingEvent> logs = new ListAppender<>();
  private final Logger logger = (Logger) LoggerFactory.getLogger(PeticionesLentasFilter.class);

  @BeforeEach
  void capturarLogs() {
    logs.start();
    logger.addAppender(logs);
  }

  @AfterEach
  void soltarLogs() {
    logger.detachAppender(logs);
  }

  @Test
  void avisaCuandoLaPeticionSuperaElUmbral() throws Exception {
    filtrarTardando(750);

    assertThat(logs.list).hasSize(1);
    assertThat(logs.list.get(0).getFormattedMessage())
        .contains("GET /api/v1/reservas")
        .contains("750 ms")
        .doesNotContain("cliente=ana");
  }

  @Test
  void noDiceNadaSiLaPeticionEsRapida() throws Exception {
    filtrarTardando(120);

    assertThat(logs.list).isEmpty();
  }

  private void filtrarTardando(long ms) throws Exception {
    var filtro = new PeticionesLentasFilter(500, ahoraNanos::get);
    var request = new MockHttpServletRequest("GET", "/api/v1/reservas");
    request.setQueryString("cliente=ana");
    filtro.doFilter(
        request,
        new MockHttpServletResponse(),
        (req, res) -> ahoraNanos.addAndGet(TimeUnit.MILLISECONDS.toNanos(ms)));
  }
}
