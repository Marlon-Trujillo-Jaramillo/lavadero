package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.SubscriptionPlan;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionPlanRepository {

  Optional<SubscriptionPlan> findById(UUID id);

  Optional<SubscriptionPlan> findDefault();

  SubscriptionPlan save(SubscriptionPlan plan);
}
