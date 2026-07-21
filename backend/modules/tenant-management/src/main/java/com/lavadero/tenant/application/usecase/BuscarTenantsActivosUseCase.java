package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Búsqueda pública (sin autenticación) de tenants activos por nombre, usada por la pantalla de
 * selección de lavadero en la app móvil.
 */
@Service
public class BuscarTenantsActivosUseCase implements UseCase<String, List<TenantResumenDto>> {

  private final TenantRepository tenantRepository;

  public BuscarTenantsActivosUseCase(TenantRepository tenantRepository) {
    this.tenantRepository = tenantRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<TenantResumenDto> execute(String query) {
    String texto = query == null ? "" : query;
    return tenantRepository.buscarActivosPorNombre(texto).stream()
        .map(t -> new TenantResumenDto(t.getId(), t.getSlug(), t.getNombre()))
        .toList();
  }
}
