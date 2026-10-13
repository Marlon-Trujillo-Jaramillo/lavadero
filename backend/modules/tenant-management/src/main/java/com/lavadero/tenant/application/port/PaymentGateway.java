package com.lavadero.tenant.application.port;

import com.lavadero.tenant.domain.model.Pago;
import java.time.Instant;
import java.util.Optional;

/**
 * Puerto hacia la pasarela de pago (implementación real: {@code WompiPaymentGateway} en
 * `infrastructure/payment`) — `application` no conoce Wompi, solo esta abstracción, mismo patrón
 * que {@code TokenService} en identity-access.
 */
public interface PaymentGateway {

  /**
   * Datos que el cliente necesita para abrir el checkout de la pasarela para {@code pago}, firmados
   * en el servidor (el secreto de integridad nunca sale del backend). Lanza {@code
   * ValidationException} si la pasarela no está configurada en este ambiente.
   */
  DatosCheckout prepararCheckout(Pago pago);

  /**
   * Verifica que un payload de webhook realmente vino de la pasarela (no de un tercero falsificando
   * la llamada) usando el secreto compartido configurado. A diferencia de otras pasarelas, Wompi
   * embebe el checksum DENTRO del propio payload ({@code signature.checksum}), no en un header —
   * por eso esta verificación no recibe una firma aparte. Sin secreto configurado, siempre {@code
   * false} (falla cerrado).
   */
  boolean firmaValida(String payloadCrudo);

  /**
   * Extrae el resultado de una transacción de un payload de webhook ya verificado. Vacío si el
   * payload no es un evento de transacción o le faltan campos.
   */
  Optional<EventoTransaccion> parsearEventoTransaccion(String payloadCrudo);

  record DatosCheckout(
      String urlCheckout,
      String llavePublica,
      String referencia,
      long montoEnCentavos,
      String moneda,
      String firmaIntegridad,
      String urlRedireccion) {}

  /**
   * @param emitidoEn instante en que la pasarela firmó el evento (forma parte del checksum), para
   *     rechazar eventos viejos reenviados.
   */
  record EventoTransaccion(
      String referencia,
      String idTransaccionExterna,
      EstadoTransaccion estado,
      long montoEnCentavos,
      String moneda,
      Instant emitidoEn) {}

  enum EstadoTransaccion {
    APROBADA,
    RECHAZADA,
    /** Todavía sin resultado final (p. ej. PSE en curso): no cambia nada. */
    EN_CURSO
  }
}
