package com.lavadero.shared.security;

import com.lavadero.shared.application.exception.ForbiddenException;
import java.util.Objects;
import java.util.UUID;

/**
 * Hasta dónde llega un usuario de staff dentro de su tenant. Solo ADMIN_TENANT y SUPER_ADMIN ven
 * todo el tenant (RLS ya lo acota al tenant); cualquier otro (ADMIN_SUCURSAL, EMPLEADO) queda
 * limitado a su propia sucursal ({@code sucursal_id} del JWT). Sin sucursal asignada, toda
 * operación sobre una sucursal se rechaza con 403.
 *
 * <p>Lo construye el controller a partir de {@link PrincipalAutenticado} y viaja en el
 * comando/query hasta el caso de uso, que es quien aplica la regla: así la autorización no depende
 * de que cada endpoint se acuerde de una expresión {@code @PreAuthorize} distinta.
 */
public final class AlcanceSucursal {

  private static final AlcanceSucursal TODO_EL_TENANT = new AlcanceSucursal(false, null);

  private final boolean restringido;
  private final UUID sucursalId;

  private AlcanceSucursal(boolean restringido, UUID sucursalId) {
    this.restringido = restringido;
    this.sucursalId = sucursalId;
  }

  public static AlcanceSucursal de(PrincipalAutenticado principal) {
    Objects.requireNonNull(principal, "principal no puede ser nulo");
    boolean soloSucursal =
        !principal.roles().contains("ADMIN_TENANT") && !principal.roles().contains("SUPER_ADMIN");
    return soloSucursal ? new AlcanceSucursal(true, principal.sucursalId()) : TODO_EL_TENANT;
  }

  public static AlcanceSucursal todoElTenant() {
    return TODO_EL_TENANT;
  }

  public boolean esRestringido() {
    return restringido;
  }

  /** Lanza {@link ForbiddenException} si {@code sucursalId} queda fuera del alcance. */
  public void verificar(UUID sucursalIdObjetivo) {
    if (!restringido) {
      return;
    }
    exigirSucursalAsignada();
    if (!sucursalId.equals(sucursalIdObjetivo)) {
      throw new ForbiddenException("Solo puedes operar sobre tu propia sucursal");
    }
  }

  private void exigirSucursalAsignada() {
    if (sucursalId == null) {
      throw new ForbiddenException("Tu usuario no tiene una sucursal asignada");
    }
  }

  /**
   * Para filtros opcionales: con alcance restringido devuelve la sucursal propia (y rechaza pedir
   * otra); sin restricción devuelve lo pedido, {@code null} = todo el tenant.
   */
  public UUID resolverFiltro(UUID sucursalIdSolicitada) {
    if (!restringido) {
      return sucursalIdSolicitada;
    }
    if (sucursalIdSolicitada != null) {
      verificar(sucursalIdSolicitada);
    }
    exigirSucursalAsignada();
    return sucursalId;
  }
}
