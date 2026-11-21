package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.PromocionDto;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Promociones del lavadero con sus resultados: dos consultas, sin N+1. */
@Service
public class ListarPromocionesUseCase {

  private final PromocionRepository promocionRepository;

  public ListarPromocionesUseCase(PromocionRepository promocionRepository) {
    this.promocionRepository = promocionRepository;
  }

  @Transactional(readOnly = true)
  public List<PromocionDto> execute() {
    var resultados = promocionRepository.resultados();
    return promocionRepository.listar().stream()
        .map(p -> PromocionMapper.toDto(p, resultados.get(p.getId())))
        .toList();
  }
}
