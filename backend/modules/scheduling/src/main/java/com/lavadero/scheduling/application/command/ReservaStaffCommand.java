package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/**
 * Acción del staff sobre una reserva concreta (iniciar, completar, ver checklist). {@code alcance}
 * viene del {@code PrincipalAutenticado} en el controller: un ADMIN_SUCURSAL solo toca reservas de
 * su sucursal.
 */
public record ReservaStaffCommand(UUID reservaId, AlcanceSucursal alcance) {}
