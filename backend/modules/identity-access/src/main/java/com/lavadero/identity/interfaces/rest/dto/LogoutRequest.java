package com.lavadero.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * DECISIÓN: el contrato público de {@code POST /api/v1/auth/logout} no especifica un shape de body
 * explícito más allá de "autenticado"; como {@code LogoutUseCase} necesita saber QUÉ refresh token
 * revocar (el logout es por sesión/dispositivo, no revoca todas las sesiones del usuario), se exige
 * el mismo shape mínimo {@code {refreshToken}} usado en {@code /refresh}, consistente con esos
 * endpoints.
 */
public record LogoutRequest(@NotBlank String refreshToken) {}
