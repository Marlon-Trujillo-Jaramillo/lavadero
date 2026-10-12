package com.lavadero.scheduling.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ChecklistItemJpaRepository extends JpaRepository<ChecklistItemJpaEntity, UUID> {

  List<ChecklistItemJpaEntity> findByReservaId(UUID reservaId);

  Optional<ChecklistItemJpaEntity> findByReservaIdAndTipo(UUID reservaId, String tipo);
}
