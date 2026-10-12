package com.lavadero.tenant.application.command;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record ActualizarSubscriptionPlanCommand(
    UUID planId,
    String nombre,
    BigDecimal precio,
    int maxSucursales,
    int maxEmpleados,
    List<String> features) {}
