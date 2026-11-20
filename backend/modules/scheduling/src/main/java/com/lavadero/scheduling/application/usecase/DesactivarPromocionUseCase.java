package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Desactiva una promoción: deja de aplicarse a reservas nuevas. Las ya hechas conservan su precio.
 */
@Service
public class DesactivarPromocionUseCase implements UseCase<UUID, Void> {

  private final PromocionRepository promocionRepository;

  public DesactivarPromocionUseCase(PromocionRepository promocionRepository) {
    this.promocionRepository = promocionRepository;
  }

  @Override
  @Transactional
  public Void execute(UUID promocionId) {
    Promocion promocion =
        promocionRepository
            .findById(promocionId)
            .orElseThrow(() -> NotFoundException.de("Promoción", promocionId));
    promocion.desactivar();
    promocionRepository.save(promocion);
    return null;
  }
}
