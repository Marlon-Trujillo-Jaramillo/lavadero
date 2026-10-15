package com.lavadero.tenant.application.dto;

/**
 * Desenlace de un webhook de la pasarela. La capa REST lo traduce a HTTP: la pasarela reintenta
 * todo lo que no sea 200, así que un evento auténtico que se decide ignorar igual responde 200.
 */
public enum ResultadoEventoPago {
  /** Firma ausente/incorrecta: no vino de la pasarela. */
  FIRMA_INVALIDA,
  /** Firma correcta pero timestamp fuera de la ventana tolerada (posible reenvío de un evento). */
  EVENTO_VENCIDO,
  /** Auténtico, pero sin efecto (duplicado, sin pago asociado, monto que no cuadra, en curso). */
  IGNORADO,
  /** Auténtico y aplicado al pago. */
  PROCESADO
}
