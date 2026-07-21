package com.lavadero.identity.application.dto;

import java.util.Set;
import java.util.UUID;

public record UsuarioAutenticadoDto(
    UUID id, String email, Set<String> roles, UUID tenantId, UUID sucursalId) {}
