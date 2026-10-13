package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.tenant.application.dto.PagoDto;
import com.lavadero.tenant.domain.repository.PagoRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Historial de pagos de suscripción del tenant actual (más reciente primero), acotado por RLS. El
 * input es el máximo de filas (ya acotado por el controller).
 */
@Service
public class ListarPagosUseCase implements UseCase<Integer, List<PagoDto>> {

  private final PagoRepository pagoRepository;

  public ListarPagosUseCase(PagoRepository pagoRepository) {
    this.pagoRepository = pagoRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<PagoDto> execute(Integer limite) {
    return pagoRepository.findRecientesDelTenantActual(limite).stream()
        .map(PagoMapper::toDto)
        .toList();
  }
}
