package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.application.command.ActualizarSubscriptionPlanCommand;
import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * {@link SubscriptionPlan} no expone mutadores (es un value-holder inmutable con validación en el
 * constructor) — "actualizar" reconstruye el aggregate con el mismo id y lo guarda; {@code save}
 * hace upsert por id (ver {@code SubscriptionPlanRepositoryAdapter}).
 */
@Service
public class ActualizarSubscriptionPlanUseCase
    implements UseCase<ActualizarSubscriptionPlanCommand, SubscriptionPlanDto> {

  private final SubscriptionPlanRepository subscriptionPlanRepository;

  public ActualizarSubscriptionPlanUseCase(SubscriptionPlanRepository subscriptionPlanRepository) {
    this.subscriptionPlanRepository = subscriptionPlanRepository;
  }

  @Override
  @Transactional
  public SubscriptionPlanDto execute(ActualizarSubscriptionPlanCommand input) {
    SubscriptionPlan existente =
        subscriptionPlanRepository
            .findById(input.planId())
            .orElseThrow(() -> NotFoundException.de("Plan de suscripción", input.planId()));

    SubscriptionPlan actualizado =
        new SubscriptionPlan(
            existente.getId(),
            input.nombre(),
            Money.cop(input.precio()),
            input.maxSucursales(),
            input.maxEmpleados(),
            input.features() == null ? List.of() : input.features());

    return SubscriptionPlanMapper.toDto(subscriptionPlanRepository.save(actualizado));
  }
}
