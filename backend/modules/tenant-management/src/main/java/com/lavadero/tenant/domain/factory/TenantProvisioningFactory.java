package com.lavadero.tenant.domain.factory;

import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.model.Tenant;
import java.util.UUID;

/**
 * Encapsula la regla de negocio de onboarding: todo tenant nuevo nace con exactamente una sucursal
 * por defecto llamada "Principal". Vive en `domain/factory` (no en `application`) porque es una
 * invariante de dominio, no un detalle de orquestación de casos de uso.
 */
public final class TenantProvisioningFactory {

  private TenantProvisioningFactory() {}

  public static Resultado provisionar(
      String nombre, String nit, String slug, UUID subscriptionPlanId) {
    Tenant tenant = Tenant.nuevo(nombre, nit, slug, subscriptionPlanId);
    Sucursal sucursalPrincipal = Sucursal.principal(tenant.getId());
    return new Resultado(tenant, sucursalPrincipal);
  }

  /** Resultado del provisioning: el tenant recién creado y su sucursal principal. */
  public record Resultado(Tenant tenant, Sucursal sucursalPrincipal) {}
}
