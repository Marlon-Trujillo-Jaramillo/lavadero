package com.lavadero.tenant.infrastructure.payment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.application.port.PaymentGateway.DatosCheckout;
import com.lavadero.tenant.application.port.PaymentGateway.EstadoTransaccion;
import com.lavadero.tenant.application.port.PaymentGateway.EventoTransaccion;
import com.lavadero.tenant.domain.model.Pago;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class WompiPaymentGatewayTest {

  private static final String SECRETO_EVENTOS = "test_events_secreto";
  private static final long TIMESTAMP = 1_760_000_000L;

  private WompiProperties properties;
  private WompiPaymentGateway gateway;

  @BeforeEach
  void setUp() {
    properties = new WompiProperties();
    properties.setPublicKey("pub_test_abc");
    properties.setIntegritySecret("test_integrity_secreto");
    properties.setEventsSecret(SECRETO_EVENTOS);
    properties.setRedirectUrl("https://admin.lavadero.com/pagos");
    gateway = new WompiPaymentGateway(properties, new ObjectMapper());
  }

  @Test
  void firmaDeIntegridadSigueLaFormulaDeWompi() {
    Pago pago =
        Pago.nuevo(
            UUID.randomUUID(),
            UUID.randomUUID(),
            Money.cop(new BigDecimal("99000")),
            "r1",
            Instant.now());

    DatosCheckout checkout = gateway.prepararCheckout(pago);

    assertThat(checkout.montoEnCentavos()).isEqualTo(9_900_000L);
    assertThat(checkout.moneda()).isEqualTo("COP");
    assertThat(checkout.llavePublica()).isEqualTo("pub_test_abc");
    assertThat(checkout.firmaIntegridad())
        .isEqualTo(WompiPaymentGateway.sha256Hex("r19900000COPtest_integrity_secreto"));
  }

  @Test
  void sinCredencialesElCheckoutFallaCerrado() {
    properties.setIntegritySecret("");
    Pago pago =
        Pago.nuevo(
            UUID.randomUUID(),
            UUID.randomUUID(),
            Money.cop(new BigDecimal("1000")),
            "r1",
            Instant.now());

    assertThatThrownBy(() -> gateway.prepararCheckout(pago))
        .isInstanceOf(ValidationException.class);
  }

  @Test
  void aceptaUnEventoFirmadoCorrectamente() {
    String payload =
        evento("tx-1", "APPROVED", 9_900_000L, firmaDe("tx-1", "APPROVED", 9_900_000L));

    assertThat(gateway.firmaValida(payload)).isTrue();
    // Wompi documenta el checksum en mayúsculas: la comparación no distingue.
    assertThat(
            gateway.firmaValida(
                evento(
                    "tx-1",
                    "APPROVED",
                    9_900_000L,
                    firmaDe("tx-1", "APPROVED", 9_900_000L).toUpperCase())))
        .isTrue();
  }

  @Test
  void rechazaUnEventoConUnCampoFirmadoAlterado() {
    String firmaOriginal = firmaDe("tx-1", "DECLINED", 9_900_000L);

    assertThat(gateway.firmaValida(evento("tx-1", "APPROVED", 9_900_000L, firmaOriginal)))
        .isFalse();
    assertThat(gateway.firmaValida(evento("tx-1", "DECLINED", 100L, firmaOriginal))).isFalse();
  }

  @Test
  void rechazaUnEventoQueNoFirmaLosCamposRequeridos() {
    // Un checksum "válido" que solo cubre transaction.id: el estado y el monto quedarían sin
    // proteger, así que no se acepta aunque cuadre.
    String checksum = WompiPaymentGateway.sha256Hex("tx-1" + TIMESTAMP + SECRETO_EVENTOS);
    String payload =
        """
        {"event":"transaction.updated",
         "data":{"transaction":{"id":"tx-1","status":"APPROVED","amount_in_cents":1,
                                "currency":"COP","reference":"r"}},
         "signature":{"properties":["transaction.id"],"checksum":"%s"},
         "timestamp":%d}
        """
            .formatted(checksum, TIMESTAMP);

    assertThat(gateway.firmaValida(payload)).isFalse();
  }

  @Test
  void sinSecretoDeEventosNingunaFirmaEsValida() {
    String payload =
        evento("tx-1", "APPROVED", 9_900_000L, firmaDe("tx-1", "APPROVED", 9_900_000L));
    properties.setEventsSecret("");

    assertThat(gateway.firmaValida(payload)).isFalse();
  }

  @Test
  void payloadMalformadoNoEsValidoNiParseable() {
    assertThat(gateway.firmaValida("no es json")).isFalse();
    assertThat(gateway.parsearEventoTransaccion("no es json")).isEmpty();
  }

  @Test
  void parseaElEventoConMontoMonedaYTimestamp() {
    String payload = evento("tx-9", "VOIDED", 500L, "x");

    EventoTransaccion evento = gateway.parsearEventoTransaccion(payload).orElseThrow();

    assertThat(evento.idTransaccionExterna()).isEqualTo("tx-9");
    assertThat(evento.estado()).isEqualTo(EstadoTransaccion.RECHAZADA);
    assertThat(evento.montoEnCentavos()).isEqualTo(500L);
    assertThat(evento.moneda()).isEqualTo("COP");
    assertThat(evento.referencia()).isEqualTo("ref-1");
    assertThat(evento.emitidoEn()).isEqualTo(Instant.ofEpochSecond(TIMESTAMP));
  }

  private static String firmaDe(String id, String estado, long monto) {
    return WompiPaymentGateway.sha256Hex(id + estado + monto + TIMESTAMP + SECRETO_EVENTOS);
  }

  private static String evento(String id, String estado, long monto, String checksum) {
    return """
        {"event":"transaction.updated",
         "data":{"transaction":{"id":"%s","status":"%s","amount_in_cents":%d,
                                "currency":"COP","reference":"ref-1"}},
         "environment":"test",
         "signature":{"properties":["transaction.id","transaction.status",
                                    "transaction.amount_in_cents"],"checksum":"%s"},
         "timestamp":%d,
         "sent_at":"2025-10-09T08:35:20.000Z"}
        """
        .formatted(id, estado, monto, checksum, TIMESTAMP);
  }
}
