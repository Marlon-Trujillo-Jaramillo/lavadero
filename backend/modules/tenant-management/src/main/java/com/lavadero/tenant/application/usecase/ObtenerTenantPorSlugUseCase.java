package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.TenantRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resuelve un tenant por su slug (subdominio). Usado tanto por la pantalla pública de selección de
 * lavadero como, internamente, por el flujo de login (header {@code X-Tenant-Slug}) para saber en
 * qué tenant autenticar.
 */
@Service
public class ObtenerTenantPorSlugUseCase implements UseCase<String, TenantResumenDto> {

  private final TenantRepository tenantRepository;

  public ObtenerTenantPorSlugUseCase(TenantRepository tenantRepository) {
    this.tenantRepository = tenantRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public TenantResumenDto execute(String slug) {
    Tenant tenant =
        tenantRepository
            .findBySlug(slug)
            .filter(Tenant::estaActivo)
            .orElseThrow(() -> NotFoundException.de("Tenant", slug));
    return new TenantResumenDto(tenant.getId(), tenant.getSlug(), tenant.getNombre());
  }
}
