package com.lavadero.tenant.application.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record SubscriptionPlanDto(
    UUID id,
    String nombre,
    BigDecimal precio,
    String moneda,
    int maxSucursales,
    int maxEmpleados,
    List<String> features) {}
