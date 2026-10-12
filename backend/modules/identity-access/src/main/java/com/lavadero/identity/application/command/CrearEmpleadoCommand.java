package com.lavadero.identity.application.command;

import java.util.UUID;

public record CrearEmpleadoCommand(String email, String password, String nombre, UUID sucursalId) {}
