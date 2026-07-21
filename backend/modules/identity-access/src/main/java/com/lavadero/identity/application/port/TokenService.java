package com.lavadero.identity.application.port;

import com.lavadero.identity.domain.model.Usuario;
import java.time.Duration;

/**
 * Puerto de emisión de tokens. La implementación (JJWT/HS256) vive en
 * `infrastructure/security.JwtTokenService`. `application` solo conoce este contrato, nunca la
 * librería jjwt directamente.
 */
public interface TokenService {

  /** Genera un access token (JWT) firmado con los claims del usuario autenticado. */
  String generarAccessToken(Usuario usuario);

  /** Duración de validez del access token, para informarla en la respuesta de login/refresh. */
  Duration duracionAccessToken();

  /** Genera un identificador opaco de refresh token (no es un JWT, solo aleatoriedad segura). */
  String generarRefreshTokenOpaco();
}
