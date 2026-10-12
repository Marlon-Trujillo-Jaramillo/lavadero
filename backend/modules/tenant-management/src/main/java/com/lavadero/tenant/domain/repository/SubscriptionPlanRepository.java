package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.SubscriptionPlan;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionPlanRepository {

  Optional<SubscriptionPlan> findById(UUID id);

  Optional<SubscriptionPlan> findDefault();

  /** Catálogo completo de planes — dato de plataforma, sin RLS (ver V1__tenant_management.sql). */
  List<SubscriptionPlan> findAll();

  SubscriptionPlan save(SubscriptionPlan plan);
}
