package com.lavadero.tenant.infrastructure.persistence;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface SubscriptionPlanJpaRepository extends JpaRepository<SubscriptionPlanJpaEntity, UUID> {}
