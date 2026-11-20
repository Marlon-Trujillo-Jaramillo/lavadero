package com.lavadero.bootstrap.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.domain.model.Placa;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;

class GlobalExceptionHandlerTest {

  private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
  private final MockHttpServletRequest request =
      new MockHttpServletRequest("POST", "/api/v1/vehiculos");

  @Test
  void unDatoInvalidoDelDominioEsUn400ConSuMensaje() {
    IllegalArgumentException ex = capturar(() -> Placa.de("¡!"));

    var respuesta = handler.handleReglaDeDominio(ex, request);

    assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(respuesta.getBody().message()).contains("placa");
  }

  @Test
  void unaTransicionInvalidaDelDominioEsUn409() {
    IllegalStateException ex =
        new IllegalStateException("Solo una reserva PENDIENTE puede iniciarse");
    ex.setStackTrace(
        new StackTraceElement[] {
          new StackTraceElement(
              "com.lavadero.scheduling.domain.model.Reserva", "iniciar", "Reserva.java", 1)
        });

    var respuesta = handler.handleReglaDeDominio(ex, request);

    assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
    assertThat(respuesta.getBody().message()).contains("PENDIENTE");
  }

  @Test
  void unaExcepcionDeUnaLibreriaSigueSiendoUn500SinExponerElMensaje() {
    IllegalArgumentException ex = capturar(() -> UUID.fromString("no-es-un-uuid"));

    var respuesta = handler.handleReglaDeDominio(ex, request);

    assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
    assertThat(respuesta.getBody().message()).isEqualTo("Error interno inesperado");
  }

  @SuppressWarnings("unchecked")
  private static <T extends RuntimeException> T capturar(Runnable accion) {
    try {
      accion.run();
    } catch (RuntimeException e) {
      return (T) e;
    }
    throw new AssertionError("se esperaba una excepción");
  }
}
