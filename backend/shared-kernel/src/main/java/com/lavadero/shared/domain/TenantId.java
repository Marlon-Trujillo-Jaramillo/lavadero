package com.lavadero.shared.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Value object que identifica un tenant. Envolver el UUID evita mezclar por accidente un {@code
 * UUID} de tenant con el de cualquier otra entidad en las firmas de los casos de uso y
 * repositorios.
 */
public final class TenantId {

  private final UUID valor;

  private TenantId(UUID valor) {
    this.valor = Objects.requireNonNull(valor, "el id de tenant no puede ser nulo");
  }

  public static TenantId de(UUID valor) {
    return new TenantId(valor);
  }

  public static TenantId de(String valor) {
    return new TenantId(UUID.fromString(valor));
  }

  public static TenantId nuevo() {
    return new TenantId(UUID.randomUUID());
  }

  public UUID valor() {
    return valor;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (!(o instanceof TenantId tenantId)) {
      return false;
    }
    return valor.equals(tenantId.valor);
  }

  @Override
  public int hashCode() {
    return valor.hashCode();
  }

  @Override
  public String toString() {
    return valor.toString();
  }
}
