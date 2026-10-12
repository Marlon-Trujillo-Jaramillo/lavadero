package com.lavadero.tenant.interfaces.rest.dto;

import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record SubscriptionPlanResponse(
    UUID id,
    String nombre,
    BigDecimal precio,
    String moneda,
    int maxSucursales,
    int maxEmpleados,
    List<String> features) {

  public static SubscriptionPlanResponse from(SubscriptionPlanDto dto) {
    return new SubscriptionPlanResponse(
        dto.id(),
        dto.nombre(),
        dto.precio(),
        dto.moneda(),
        dto.maxSucursales(),
        dto.maxEmpleados(),
        dto.features());
  }
}
