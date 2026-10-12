package com.lavadero.identity.application.dto;

import java.util.UUID;

public record EmpleadoDto(UUID id, String email, String nombre, UUID sucursalId, String estado) {}
