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
import com.lavadero.scheduling.application.command.CancelarReservaCommand;
import com.lavadero.scheduling.application.command.CrearPromocionCommand;
import com.lavadero.scheduling.application.command.CrearReservaCommand;
import com.lavadero.scheduling.domain.model.PromocionAplicada;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.Descuento;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.model.promocion.TipoDescuento;
import com.lavadero.scheduling.domain.model.promocion.TipoPromocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class PromocionUseCasesTest {

  private static final Instant AHORA = Instant.parse("2026-11-20T15:00:00Z");
  private static final Instant INICIO = Instant.parse("2026-11-25T15:00:00Z");
  private static final LocalDate HOY = LocalDate.of(2026, 11, 20);

  private final UUID tenant = UUID.randomUUID();
  private final UUID cliente = UUID.randomUUID();
  private final ReservaRepository reservas = mock(ReservaRepository.class);
  private final PromocionRepository promociones = mock(PromocionRepository.class);
  private final Clock reloj = Clock.fixed(AHORA, ZoneOffset.UTC);

  @BeforeEach
  void fijarTenant() {
    TenantContext.set(tenant);
    when(promociones.findHorariosActivos()).thenReturn(List.of());
    when(reservas.findActivasPorSucursalYRango(any(), any(), any())).thenReturn(List.of());
    when(reservas.save(any())).thenAnswer(i -> i.getArgument(0));
  }

  @AfterEach
  void limpiarTenant() {
    TenantContext.clear();
  }

  @Test
  void laReservaConCuponCobraElPrecioConDescuentoYGastaUnUso() {
    Promocion cupon = cupon("HOLA10", 10);
    when(promociones.findCuponActivo(CodigoCupon.de("HOLA10"))).thenReturn(Optional.of(cupon));
    when(promociones.reservarUso(cupon.getId())).thenReturn(true);

    var creada = crearReserva().execute(comando(" hola10 "));

    ArgumentCaptor<Reserva> guardada = ArgumentCaptor.forClass(Reserva.class);
    verify(reservas).save(guardada.capture());
    assertThat(guardada.getValue().getPrecio().monto()).isEqualByComparingTo("40500");
    assertThat(guardada.getValue().getPromocion())
        .contains(new PromocionAplicada(cupon.getId(), Money.cop(new BigDecimal("45000"))));
    assertThat(creada.precioLista()).isEqualByComparingTo("45000");
  }

  @Test
  void siOtroClienteSeLlevoElUltimoCupoLaReservaNoSeCrea() {
    Promocion cupon = cupon("ULTIMO", 50);
    when(promociones.findCuponActivo(CodigoCupon.de("ULTIMO"))).thenReturn(Optional.of(cupon));
    when(promociones.reservarUso(cupon.getId())).thenReturn(false);

    assertThatThrownBy(() -> crearReserva().execute(comando("ULTIMO")))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("agotar");
    verify(reservas, never()).save(any());
  }

  @Test
  void unCuponQueNoExisteSeExplicaEnVezDeIgnorarse() {
    when(promociones.findCuponActivo(any())).thenReturn(Optional.empty());

    assertThatThrownBy(() -> crearReserva().execute(comando("NOEXISTE")))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("NOEXISTE");
    assertThatThrownBy(() -> crearReserva().execute(comando("%%")))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("no existe");
    verify(reservas, never()).save(any());
  }

  @Test
  void cancelarDevuelveElUsoDeLaPromocion() {
    UUID promocionId = UUID.randomUUID();
    Reserva conCupon =
        new Reserva(
            UUID.randomUUID(),
            tenant,
            UUID.randomUUID(),
            UUID.randomUUID(),
            cliente,
            INICIO,
            30,
            Money.cop(new BigDecimal("40500")),
            ReservaEstado.PENDIENTE,
            null,
            new PromocionAplicada(promocionId, Money.cop(new BigDecimal("45000"))));
    when(reservas.findById(conCupon.getId())).thenReturn(Optional.of(conCupon));

    new CancelarReservaUseCase(reservas, promociones)
        .execute(
            new CancelarReservaCommand(
                conCupon.getId(), cliente, false, AlcanceSucursal.todoElTenant()));

    verify(promociones).liberarUso(promocionId);
  }

  @Test
  void noSePuedeCrearUnCuponConUnCodigoActivoRepetidoNiConVigenciaVencida() {
    when(promociones.findCuponActivo(CodigoCupon.de("HOLA10")))
        .thenReturn(Optional.of(cupon("HOLA10", 10)));
    var crear = new CrearPromocionUseCase(promociones, reloj);

    assertThatThrownBy(() -> crear.execute(nuevoCupon("hola10", HOY.plusDays(10))))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("HOLA10");
    assertThatThrownBy(() -> crear.execute(nuevoCupon("OTRO", HOY.minusDays(1))))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("vigencia");
    verify(promociones, never()).save(any());
  }

  private CrearReservaUseCase crearReserva() {
    var servicios = mock(ObtenerServicioPorIdUseCase.class);
    var sucursales = mock(ObtenerSucursalPorIdUseCase.class);
    when(servicios.execute(any()))
        .thenReturn(
            new ServicioDto(
                UUID.randomUUID(), "Lavado", null, 30, new BigDecimal("45000"), "COP", true));
    when(sucursales.execute(any()))
        .thenReturn(new SucursalDto(UUID.randomUUID(), "Principal", null, 2));
    return new CrearReservaUseCase(
        reservas,
        servicios,
        sucursales,
        mock(VehiculoRepository.class),
        promociones,
        new ResolvedorPromociones(promociones));
  }

  private CrearReservaCommand comando(String cupon) {
    return new CrearReservaCommand(
        cliente, UUID.randomUUID(), UUID.randomUUID(), INICIO, null, cupon);
  }

  private Promocion cupon(String codigo, int porcentaje) {
    return Promocion.cupon(
        tenant,
        "Cupón " + codigo,
        CodigoCupon.de(codigo),
        Descuento.porcentaje(porcentaje),
        HOY,
        HOY.plusDays(30),
        100,
        AHORA);
  }

  private static CrearPromocionCommand nuevoCupon(String codigo, LocalDate hasta) {
    return new CrearPromocionCommand(
        "Bienvenida",
        TipoPromocion.CUPON,
        codigo,
        TipoDescuento.PORCENTAJE,
        new BigDecimal("10"),
        null,
        null,
        null,
        null,
        HOY,
        hasta,
        null);
  }
}
