package com.lavadero.identity.infrastructure.security;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

/** Endurecimiento del webhook público de Wompi: tope de tamaño y rate limit propio. */
class FiltrosWebhookPublicoTest {

  private static final String WEBHOOK = "/api/v1/pagos/webhook/wompi";

  @Test
  void unCuerpoDeMasDe64KbSeRechazaCon413() throws Exception {
    MockHttpServletRequest request = post(WEBHOOK, new byte[64 * 1024 + 1]);
    MockHttpServletResponse response = new MockHttpServletResponse();
    MockFilterChain cadena = new MockFilterChain();

    new LimiteCuerpoFilter().doFilter(request, response, cadena);

    assertThat(response.getStatus()).isEqualTo(413);
    assertThat(cadena.getRequest()).as("no llega al controlador").isNull();
  }

  @Test
  void unCuerpoChunkedGrandeTambienSeRechaza() throws Exception {
    MockHttpServletRequest sinLongitud =
        new MockHttpServletRequest() {
          @Override
          public long getContentLengthLong() {
            return -1;
          }
        };
    sinLongitud.setMethod("POST");
    sinLongitud.setRequestURI(WEBHOOK);
    sinLongitud.setContent(new byte[70 * 1024]);
    MockHttpServletResponse response = new MockHttpServletResponse();

    new LimiteCuerpoFilter().doFilter(sinLongitud, response, new MockFilterChain());

    assertThat(response.getStatus()).isEqualTo(413);
  }

  @Test
  void unCuerpoNormalLlegaIntactoAlControlador() throws Exception {
    byte[] payload = "{\"event\":\"transaction.updated\"}".getBytes(StandardCharsets.UTF_8);
    AtomicReference<String> leido = new AtomicReference<>();
    MockFilterChain cadena =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest req, ServletResponse res) throws IOException {
            leido.set(
                new String(
                    ((HttpServletRequest) req).getInputStream().readAllBytes(),
                    StandardCharsets.UTF_8));
          }
        };

    new LimiteCuerpoFilter()
        .doFilter(post(WEBHOOK, payload), new MockHttpServletResponse(), cadena);

    assertThat(leido.get()).isEqualTo("{\"event\":\"transaction.updated\"}");
  }

  @Test
  void elWebhookTieneUnBucketPropioMasHolgadoQueElLogin() throws Exception {
    RateLimitFilter filtro = new RateLimitFilter();

    for (int i = 0; i < 120; i++) {
      assertThat(estado(filtro, WEBHOOK)).isEqualTo(200);
    }
    assertThat(estado(filtro, WEBHOOK)).isEqualTo(429);

    for (int i = 0; i < 5; i++) {
      assertThat(estado(filtro, "/api/v1/auth/login")).isEqualTo(200);
    }
    assertThat(estado(filtro, "/api/v1/auth/login")).isEqualTo(429);
  }

  private static int estado(RateLimitFilter filtro, String ruta) throws Exception {
    MockHttpServletResponse response = new MockHttpServletResponse();
    filtro.doFilter(post(ruta, new byte[0]), response, new MockFilterChain());
    return response.getStatus();
  }

  private static MockHttpServletRequest post(String ruta, byte[] cuerpo) {
    MockHttpServletRequest request = new MockHttpServletRequest("POST", ruta);
    request.setContent(cuerpo);
    request.setRemoteAddr("10.0.0.1");
    return request;
  }
}
