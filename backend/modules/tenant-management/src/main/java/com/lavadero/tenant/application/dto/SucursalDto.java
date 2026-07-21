package com.lavadero.tenant.application.dto;

import java.util.UUID;

public record SucursalDto(UUID id, String nombre, String direccion, int capacidadSimultanea) {}
