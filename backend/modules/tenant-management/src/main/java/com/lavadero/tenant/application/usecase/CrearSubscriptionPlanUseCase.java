package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.application.command.CrearSubscriptionPlanCommand;
import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Da de alta un plan de suscripción en el catálogo de la plataforma. Restringido a SUPER_ADMIN en
 * la capa REST — es dato de plataforma, no de un tenant (sin RLS, ver V1__tenant_management.sql).
 */
@Service
public class CrearSubscriptionPlanUseCase
    implements UseCase<CrearSubscriptionPlanCommand, SubscriptionPlanDto> {

  private final SubscriptionPlanRepository subscriptionPlanRepository;

  public CrearSubscriptionPlanUseCase(SubscriptionPlanRepository subscriptionPlanRepository) {
    this.subscriptionPlanRepository = subscriptionPlanRepository;
  }

  @Override
  @Transactional
  public SubscriptionPlanDto execute(CrearSubscriptionPlanCommand input) {
    SubscriptionPlan plan =
        new SubscriptionPlan(
            UUID.randomUUID(),
            input.nombre(),
            Money.cop(input.precio()),
            input.maxSucursales(),
            input.maxEmpleados(),
            input.features() == null ? List.of() : input.features());
    return SubscriptionPlanMapper.toDto(subscriptionPlanRepository.save(plan));
  }
}
