package com.lavadero.tenant.application.command;

import java.util.UUID;

public record ActualizarSucursalCommand(
    UUID sucursalId, String nombre, String direccion, int capacidadSimultanea) {}
