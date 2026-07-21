package com.lavadero.identity.application.command;

/**
 * {@code tenantSlug} es opcional: nulo/vacío implica intento de login de plataforma (SUPER_ADMIN).
 */
public record LoginCommand(String tenantSlug, String email, String password) {}
