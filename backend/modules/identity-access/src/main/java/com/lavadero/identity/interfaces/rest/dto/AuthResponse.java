package com.lavadero.identity.interfaces.rest.dto;

import com.lavadero.identity.application.dto.AuthResultDto;

/**
 * Shape de respuesta de {@code /login} y {@code /register}. Contrato FIJO consumido por la app
 * Flutter: renombra el campo {@code usuario} de {@link AuthResultDto} a {@code user} porque así
 * quedó pactado con el frontend; no cambiar sin coordinar ese lado.
 */
public record AuthResponse(
    String accessToken, String refreshToken, long expiresIn, UsuarioResponse user) {

  public static AuthResponse from(AuthResultDto dto) {
    return new AuthResponse(
        dto.accessToken(),
        dto.refreshToken(),
        dto.expiresIn(),
        UsuarioResponse.from(dto.usuario()));
  }
}
