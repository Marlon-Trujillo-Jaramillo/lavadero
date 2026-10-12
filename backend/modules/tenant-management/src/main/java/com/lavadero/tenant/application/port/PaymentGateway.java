package com.lavadero.tenant.application.port;

import com.lavadero.tenant.domain.model.Pago;
import java.util.Optional;

/**
 * Puerto hacia la pasarela de pago (implementación real: {@code WompiPaymentGateway} en
 * `infrastructure/payment`) — `application` no conoce Wompi, solo esta abstracción, mismo patrón
 * que {@code TokenService} en identity-access.
 */
public interface PaymentGateway {

  /** Genera un link de checkout de un solo uso para el {@code pago} dado. */
  CheckoutLink crearLinkDePago(Pago pago, String nombrePlan);

  /**
   * Verifica que un payload de webhook realmente vino de la pasarela (no de un tercero
   * falsificando la llamada) usando el secreto compartido configurado. A diferencia de otras
   * pasarelas, Wompi embebe el checksum DENTRO del propio payload ({@code signature.checksum}),
   * no en un header — por eso esta verificación no recibe una firma aparte.
   */
  boolean firmaValida(String payloadCrudo);

  /** Extrae el resultado de una transacción de un payload de webhook ya verificado. */
  Optional<ResultadoTransaccion> parsearEventoTransaccion(String payloadCrudo);

  record CheckoutLink(String url) {}

  record ResultadoTransaccion(String referencia, String idTransaccionExterna, boolean aprobado) {}
}
