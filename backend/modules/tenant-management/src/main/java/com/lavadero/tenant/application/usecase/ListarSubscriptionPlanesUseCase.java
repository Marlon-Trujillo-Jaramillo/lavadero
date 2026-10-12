package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.tenant.application.dto.SubscriptionPlanDto;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Catálogo completo de planes de suscripción de la plataforma. */
@Service
public class ListarSubscriptionPlanesUseCase implements UseCase<Void, List<SubscriptionPlanDto>> {

  private final SubscriptionPlanRepository subscriptionPlanRepository;

  public ListarSubscriptionPlanesUseCase(SubscriptionPlanRepository subscriptionPlanRepository) {
    this.subscriptionPlanRepository = subscriptionPlanRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<SubscriptionPlanDto> execute(Void input) {
    return subscriptionPlanRepository.findAll().stream()
        .map(SubscriptionPlanMapper::toDto)
        .toList();
  }
}
