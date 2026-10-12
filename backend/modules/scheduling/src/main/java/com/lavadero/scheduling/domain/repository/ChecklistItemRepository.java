package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.ChecklistItem;
import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChecklistItemRepository {

  List<ChecklistItem> findByReservaId(UUID reservaId);

  Optional<ChecklistItem> findByReservaIdAndTipo(UUID reservaId, ChecklistItemTipo tipo);

  ChecklistItem save(ChecklistItem item);
}
