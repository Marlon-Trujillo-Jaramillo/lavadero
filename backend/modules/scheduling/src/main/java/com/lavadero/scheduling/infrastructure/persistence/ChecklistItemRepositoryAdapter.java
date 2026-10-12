package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.ChecklistItem;
import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class ChecklistItemRepositoryAdapter implements ChecklistItemRepository {

  private final ChecklistItemJpaRepository jpaRepository;

  ChecklistItemRepositoryAdapter(ChecklistItemJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ChecklistItem> findByReservaId(UUID reservaId) {
    return jpaRepository.findByReservaId(reservaId).stream()
        .map(ChecklistItemRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<ChecklistItem> findByReservaIdAndTipo(UUID reservaId, ChecklistItemTipo tipo) {
    return jpaRepository
        .findByReservaIdAndTipo(reservaId, tipo.name())
        .map(ChecklistItemRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional
  public ChecklistItem save(ChecklistItem item) {
    ChecklistItemJpaEntity entity =
        new ChecklistItemJpaEntity(
            item.getId(),
            item.getTenantId(),
            item.getReservaId(),
            item.getTipo().name(),
            item.isCompletado(),
            item.getCompletadoEn());
    jpaRepository.save(entity);
    return item;
  }

  private static ChecklistItem toDomain(ChecklistItemJpaEntity entity) {
    return new ChecklistItem(
        entity.getId(),
        entity.getTenantId(),
        entity.getReservaId(),
        ChecklistItemTipo.valueOf(entity.getTipo()),
        entity.isCompletado(),
        entity.getCompletadoEn());
  }
}
