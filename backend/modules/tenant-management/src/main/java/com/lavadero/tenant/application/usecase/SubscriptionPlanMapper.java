package com.lavadero.tenant.application.usecase;

import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import com.lavadero.tenant.domain.model.SubscriptionPlan;

/** Mapeo compartido dominio→DTO entre los casos de uso de planes de suscripción. */
final class SubscriptionPlanMapper {

  private SubscriptionPlanMapper() {}

  static SubscriptionPlanDto toDto(SubscriptionPlan plan) {
    return new SubscriptionPlanDto(
        plan.getId(),
        plan.getNombre(),
        plan.getPrecio().monto(),
        plan.getPrecio().moneda().getCurrencyCode(),
        plan.getMaxSucursales(),
        plan.getMaxEmpleados(),
        plan.getFeatures());
  }
}
