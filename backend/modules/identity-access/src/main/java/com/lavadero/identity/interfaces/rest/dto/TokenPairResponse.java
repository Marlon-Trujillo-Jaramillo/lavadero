package com.lavadero.identity.interfaces.rest.dto;

import com.lavadero.identity.application.dto.AuthResultDto;

/** Shape de respuesta de {@code /refresh}: a propósito NO incluye el usuario. */
public record TokenPairResponse(String accessToken, String refreshToken, long expiresIn) {

  public static TokenPairResponse from(AuthResultDto dto) {
    return new TokenPairResponse(dto.accessToken(), dto.refreshToken(), dto.expiresIn());
  }
}
