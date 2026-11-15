package com.lavadero.identity.interfaces.rest.dto;

/**
 * Límites de los campos que llegan por los endpoints públicos de alta (registro de clientes, alta
 * de empleados y alta de lavaderos). Centralizados para que los tres formularios no se desalineen.
 *
 * <p>La contraseña tiene un máximo además del mínimo: Argon2 es costoso a propósito, y sin tope un
 * atacante podría mandar textos enormes para gastar CPU del servidor en cada intento.
 */
public final class LimitesCampos {

  public static final int PASSWORD_MIN = 8;
  public static final int PASSWORD_MAX = 128;
  public static final int EMAIL_MAX = 254;
  public static final int NOMBRE_MAX = 120;
  public static final int NIT_MAX = 30;
  public static final int SLUG_MIN = 3;
  public static final int SLUG_MAX = 40;

  private LimitesCampos() {}
}
