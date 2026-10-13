package com.lavadero.identity.application;

import java.util.Optional;
import java.util.UUID;

/**
 * Formato del refresh token entregado al cliente: {@code <tenantId>.<aleatorio>} para usuarios de
 * tenant, solo {@code <aleatorio>} para SUPER_ADMIN.
 *
 * <p>{@code POST /auth/refresh} es público, así que llega sin {@code TenantContext}, y la política
 * RLS de {@code refresh_token} (V12) oculta los tokens de tenant cuando no hay tenant fijado. El
 * prefijo dice en qué tenant buscar ANTES de la consulta. No es autorización: el hash de todo el
 * string sigue siendo el secreto, y un prefijo manipulado solo hace que no se encuentre nada.
 */
public final class RefreshTokenFormato {

  private static final char SEPARADOR = '.';

  private RefreshTokenFormato() {}

  public static String componer(UUID tenantId, String aleatorio) {
    return tenantId == null ? aleatorio : tenantId.toString() + SEPARADOR + aleatorio;
  }

  public static Optional<UUID> tenantDe(String refreshToken) {
    int separador = refreshToken.indexOf(SEPARADOR);
    if (separador <= 0) {
      return Optional.empty();
    }
    try {
      return Optional.of(UUID.fromString(refreshToken.substring(0, separador)));
    } catch (IllegalArgumentException e) {
      return Optional.empty();
    }
  }
}
