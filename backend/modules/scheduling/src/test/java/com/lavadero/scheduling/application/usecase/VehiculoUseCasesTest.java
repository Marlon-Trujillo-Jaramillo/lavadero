package com.lavadero.scheduling.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.scheduling.application.command.ArchivarVehiculoCommand;
import com.lavadero.scheduling.application.command.CrearReservaCommand;
import com.lavadero.scheduling.application.command.RegistrarVehiculoCommand;
import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.TipoVehiculo;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class VehiculoUseCasesTest {

  private final UUID tenant = UUID.randomUUID();
  private final UUID cliente = UUID.randomUUID();
  private final UUID otroCliente = UUID.randomUUID();
  private final VehiculoRepository vehiculos = mock(VehiculoRepository.class);
  private final ReservaRepository reservas = mock(ReservaRepository.class);

  @BeforeEach
  void fijarTenant() {
    TenantContext.set(tenant);
  }

  @AfterEach
  void limpiarTenant() {
    TenantContext.clear();
  }

  @Test
  void registrarNormalizaLaPlacaYRechazaUnaRepetida() {
    when(vehiculos.existeActivoConPlaca(cliente, Placa.de("ABC123"))).thenReturn(true);

    assertThatThrownBy(
            () ->
                new RegistrarVehiculoUseCase(vehiculos)
                    .execute(
                        new RegistrarVehiculoCommand(
                            cliente, "abc-123", TipoVehiculo.AUTOMOVIL, null, null)))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("ABC123");
    verify(vehiculos, never()).save(any());
  }

  @Test
  void noSePuedeArchivarElVehiculoDeOtroCliente() {
    Vehiculo ajeno = vehiculoDe(otroCliente);
    when(vehiculos.findById(ajeno.getId())).thenReturn(Optional.of(ajeno));

    assertThatThrownBy(
            () ->
                new ArchivarVehiculoUseCase(vehiculos)
                    .execute(new ArchivarVehiculoCommand(cliente, ajeno.getId())))
        .isInstanceOf(NotFoundException.class);
    assertThat(ajeno.isActivo()).isTrue();
  }

  @Test
  void noSePuedeReservarConElVehiculoDeOtroCliente() {
    Vehiculo ajeno = vehiculoDe(otroCliente);
    when(vehiculos.findById(ajeno.getId())).thenReturn(Optional.of(ajeno));

    assertThatThrownBy(() -> crearReserva().execute(comando(ajeno.getId())))
        .isInstanceOf(NotFoundException.class);
    verify(reservas, never()).save(any());
  }

  @Test
  void laReservaGuardaLaPlacaDelVehiculoElegido() {
    Vehiculo propio = vehiculoDe(cliente);
    when(vehiculos.findById(propio.getId())).thenReturn(Optional.of(propio));
    when(reservas.findActivasPorSucursalYRango(any(), any(), any())).thenReturn(List.of());
    when(reservas.save(any())).thenAnswer(i -> i.getArgument(0));

    var creada = crearReserva().execute(comando(propio.getId()));

    ArgumentCaptor<Reserva> guardada = ArgumentCaptor.forClass(Reserva.class);
    verify(reservas).save(guardada.capture());
    assertThat(guardada.getValue().getVehiculo()).isPresent();
    assertThat(creada.vehiculoPlaca()).isEqualTo("XYZ987");
  }

  private CrearReservaUseCase crearReserva() {
    var servicios = mock(ObtenerServicioPorIdUseCase.class);
    var sucursales = mock(ObtenerSucursalPorIdUseCase.class);
    when(servicios.execute(any()))
        .thenReturn(
            new ServicioDto(
                UUID.randomUUID(), "Lavado", null, 30, new BigDecimal("25000"), "COP", true));
    when(sucursales.execute(any()))
        .thenReturn(new SucursalDto(UUID.randomUUID(), "Principal", null, 2));
    var promociones = mock(PromocionRepository.class);
    return new CrearReservaUseCase(
        reservas,
        servicios,
        sucursales,
        vehiculos,
        promociones,
        new ResolvedorPromociones(promociones));
  }

  private CrearReservaCommand comando(UUID vehiculoId) {
    return new CrearReservaCommand(
        cliente,
        UUID.randomUUID(),
        UUID.randomUUID(),
        Instant.parse("2026-12-01T15:00:00Z"),
        vehiculoId);
  }

  private Vehiculo vehiculoDe(UUID dueno) {
    return Vehiculo.nuevo(tenant, dueno, Placa.de("XYZ987"), TipoVehiculo.CAMIONETA, null, null);
  }
}
