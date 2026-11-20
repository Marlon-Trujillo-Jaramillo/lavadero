package com.lavadero.scheduling.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.scheduling.application.command.FichaClienteQuery;
import com.lavadero.scheduling.application.command.ListarClientesQuery;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class ClienteCrmUseCasesTest {

  private static final Instant AHORA = Instant.parse("2026-11-20T12:00:00Z");
  private final Clock reloj = Clock.fixed(AHORA, ZoneOffset.UTC);
  private final ClienteCrmRepository crm = mock(ClienteCrmRepository.class);
  private final VehiculoRepository vehiculos = mock(VehiculoRepository.class);
  private final UUID miSucursal = UUID.randomUUID();

  @Test
  void elAdminDeSucursalSiempreVeSoloSuSucursalYElOrdenPorDefectoEsUltimaVisita() {
    when(crm.buscar(any())).thenReturn(new PaginaClientes(List.of(), 0, Map.of()));

    listar().execute(query(null, 0, 25, adminSucursal()));

    ArgumentCaptor<FiltroClientes> filtro = ArgumentCaptor.forClass(FiltroClientes.class);
    verify(crm).buscar(filtro.capture());
    assertThat(filtro.getValue().sucursalId()).isEqualTo(miSucursal);
    assertThat(filtro.getValue().orden()).isEqualTo(OrdenClientes.ULTIMA_VISITA);
    assertThat(filtro.getValue().ahora()).isEqualTo(AHORA);
  }

  @Test
  void elAdminDeSucursalNoPuedePedirOtraSucursal() {
    assertThatThrownBy(() -> listar().execute(query(UUID.randomUUID(), 0, 25, adminSucursal())))
        .isInstanceOf(ForbiddenException.class);
    verify(crm, never()).buscar(any());
  }

  @Test
  void rechazaPaginacionYBusquedaFueraDeRango() {
    AlcanceSucursal todo = AlcanceSucursal.todoElTenant();
    assertThatThrownBy(() -> listar().execute(query(null, -1, 25, todo)))
        .isInstanceOf(ValidationException.class);
    assertThatThrownBy(() -> listar().execute(query(null, 0, 0, todo)))
        .isInstanceOf(ValidationException.class);
    assertThatThrownBy(() -> listar().execute(query(null, 0, 101, todo)))
        .isInstanceOf(ValidationException.class);
    assertThatThrownBy(
            () ->
                listar()
                    .execute(
                        new ListarClientesQuery(null, "x".repeat(101), null, null, 0, 25, todo)))
        .isInstanceOf(ValidationException.class);
  }

  @Test
  void laFichaDeUnClienteFueraDelAlcanceEs404() {
    UUID cliente = UUID.randomUUID();
    when(crm.resumen(cliente, miSucursal, AHORA)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> ficha().execute(new FichaClienteQuery(cliente, null, adminSucursal())))
        .isInstanceOf(NotFoundException.class);
    verify(crm, never()).historial(any(), any(), eq(20));
  }

  @Test
  void laFichaJuntaResumenFavoritoVehiculosEHistorial() {
    UUID cliente = UUID.randomUUID();
    when(crm.resumen(cliente, null, AHORA))
        .thenReturn(
            Optional.of(
                new ClienteResumen(
                    cliente,
                    "Ana",
                    "ana@example.com",
                    3,
                    Money.cop(new BigDecimal("45000")),
                    AHORA,
                    AHORA,
                    null,
                    0,
                    SegmentoCliente.OCASIONAL)));
    when(crm.servicioFavorito(cliente, null)).thenReturn(Optional.of("Lavado"));
    when(crm.historial(cliente, null, ObtenerFichaClienteUseCase.HISTORIAL_MAXIMO))
        .thenReturn(List.of());
    when(vehiculos.findActivosByClienteId(cliente)).thenReturn(List.of());

    var dto = ficha().execute(new FichaClienteQuery(cliente, null, AlcanceSucursal.todoElTenant()));

    assertThat(dto.cliente().segmento()).isEqualTo("OCASIONAL");
    assertThat(dto.cliente().gastoTotal()).isEqualByComparingTo("45000");
    assertThat(dto.servicioFavorito()).isEqualTo("Lavado");
  }

  private ListarClientesUseCase listar() {
    return new ListarClientesUseCase(crm, reloj);
  }

  private ObtenerFichaClienteUseCase ficha() {
    return new ObtenerFichaClienteUseCase(crm, vehiculos, reloj);
  }

  private static ListarClientesQuery query(
      UUID sucursalId, int pagina, int tamano, AlcanceSucursal alcance) {
    return new ListarClientesQuery(null, null, null, sucursalId, pagina, tamano, alcance);
  }

  private AlcanceSucursal adminSucursal() {
    return AlcanceSucursal.de(
        new PrincipalAutenticado(
            UUID.randomUUID(), UUID.randomUUID(), miSucursal, Set.of("ADMIN_SUCURSAL"), "jti"));
  }
}
