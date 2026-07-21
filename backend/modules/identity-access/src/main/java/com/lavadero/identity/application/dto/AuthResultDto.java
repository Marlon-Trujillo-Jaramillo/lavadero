package com.lavadero.identity.application.dto;

public record AuthResultDto(
    String accessToken, String refreshToken, long expiresIn, UsuarioAutenticadoDto usuario) {}
