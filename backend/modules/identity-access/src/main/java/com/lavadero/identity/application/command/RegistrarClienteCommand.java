package com.lavadero.identity.application.command;

public record RegistrarClienteCommand(
    String tenantSlug, String email, String password, String nombre) {}
