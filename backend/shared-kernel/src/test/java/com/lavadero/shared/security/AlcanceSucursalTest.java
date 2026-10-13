package com.lavadero.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.shared.application.exception.ForbiddenException;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AlcanceSucursalTest {

  private static final UUID PROPIA = UUID.randomUUID();
  private static final UUID OTRA = UUID.randomUUID();

  @Test
  void empleadoYAdminSucursalQuedanEnSuSucursal() {
    for (String rol : Set.of("EMPLEADO", "ADMIN_SUCURSAL")) {
      AlcanceSucursal alcance = AlcanceSucursal.de(principal(Set.of(rol), PROPIA));

      assertThat(alcance.esRestringido()).isTrue();
      alcance.verificar(PROPIA);
      assertThatThrownBy(() -> alcance.verificar(OTRA)).isInstanceOf(ForbiddenException.class);
      assertThat(alcance.resolverFiltro(null)).isEqualTo(PROPIA);
    }
  }

  @Test
  void adminTenantYSuperAdminVenTodoElTenant() {
    for (String rol : Set.of("ADMIN_TENANT", "SUPER_ADMIN")) {
      AlcanceSucursal alcance = AlcanceSucursal.de(principal(Set.of(rol, "ADMIN_SUCURSAL"), null));

      alcance.verificar(OTRA);
      assertThat(alcance.resolverFiltro(null)).isNull();
      assertThat(alcance.resolverFiltro(OTRA)).isEqualTo(OTRA);
    }
  }

  @Test
  void sinSucursalAsignadaSeRechazaConMensajeClaro() {
    AlcanceSucursal alcance = AlcanceSucursal.de(principal(Set.of("EMPLEADO"), null));

    assertThatThrownBy(() -> alcance.verificar(PROPIA))
        .isInstanceOf(ForbiddenException.class)
        .hasMessageContaining("no tiene una sucursal asignada");
    assertThatThrownBy(() -> alcance.resolverFiltro(null))
        .hasMessageContaining("no tiene una sucursal asignada");
  }

  private static PrincipalAutenticado principal(Set<String> roles, UUID sucursalId) {
    return new PrincipalAutenticado(UUID.randomUUID(), UUID.randomUUID(), sucursalId, roles, "jti");
  }
}
