package com.lavadero.identity.application.port;

/**
 * Bloqueo temporal por cuenta tras varios logins fallidos (complementa al {@code RateLimitFilter},
 * que limita por IP: un atacante que rota IPs contra UNA cuenta solo lo frena esto). La clave
 * identifica la cuenta ({@code tenant|email}), no la IP.
 */
public interface LimitadorIntentosLogin {

  /**
   * Registra un intento ANTES de verificar la contraseña, de forma atómica, y dice si se permite.
   * Contarlo de antemano (como si fuera a fallar) cierra la carrera "consultar y luego registrar":
   * N peticiones concurrentes no pueden colarse todas por debajo del umbral. {@code false} si la
   * cuenta está bloqueada.
   */
  boolean registrarIntento(String claveCuenta);

  /** Un login correcto borra el historial de intentos (y un bloqueo recién activado). */
  void registrarExito(String claveCuenta);
}
