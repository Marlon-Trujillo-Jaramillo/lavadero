package com.lavadero.tenant.application.command;

import java.math.BigDecimal;
import java.util.List;

public record CrearSubscriptionPlanCommand(
    String nombre, BigDecimal precio, int maxSucursales, int maxEmpleados, List<String> features) {}
