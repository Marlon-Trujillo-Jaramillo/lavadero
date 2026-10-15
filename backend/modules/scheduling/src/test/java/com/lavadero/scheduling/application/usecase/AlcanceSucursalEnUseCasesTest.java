package com.lavadero.scheduling.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.scheduling.application.command.AgendaDiaQuery;
import com.lavadero.scheduling.application.command.CancelarReservaCommand;
import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.command.ResumenVentasQuery;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * ADMIN_SUCURSAL y EMPLEADO quedan acotados a su sucursal en agenda, acciones y reportes; solo
 * ADMIN_TENANT ve todo el tenant.
 */
class AlcanceSucursalEnUseCasesTest {

  private static final UUID SUCURSAL_PROPIA = UUID.randomUUID();
  private static final UUID OTRA_SUCURSAL = UUID.randomUUID();
  private static final Instant AHORA = Instant.parse("2026-10-12T10:00:00Z");

  private final ReservaRepository reservas = mock(ReservaRepository.class);

  private final AlcanceSucursal adminSucursal =
      AlcanceSucursal.de(principal(Set.of("ADMIN_SUCURSAL")));
  private final AlcanceSucursal empleado = AlcanceSucursal.de(principal(Set.of("EMPLEADO")));
  private final AlcanceSucursal adminTenant =
      AlcanceSucursal.de(principal(Set.of("ADMIN_SUCURSAL", "ADMIN_TENANT")));

  @Test
  void adminSucursalNoVeLaAgendaDeOtraSucursal() {
    var useCase = new ListarAgendaDelDiaUseCase(reservas);

    assertThatThrownBy(
            () ->
                useCase.execute(
                    new AgendaDiaQuery(OTRA_SUCURSAL, AHORA, AHORA.plusSeconds(1), adminSucursal)))
        .isInstanceOf(ForbiddenException.class);
    assertThat(
            useCase.execute(
                new AgendaDiaQuery(SUCURSAL_PROPIA, AHORA, AHORA.plusSeconds(1), adminSucursal)))
        .isEmpty();
    assertThat(
            useCase.execute(
                new AgendaDiaQuery(OTRA_SUCURSAL, AHORA, AHORA.plusSeconds(1), adminTenant)))
        .isEmpty();
  }

  @Test
  void adminSucursalNoIniciaNiCompletaReservasDeOtraSucursal() {
    Reserva ajena = reservaEn(OTRA_SUCURSAL);
    when(reservas.findById(ajena.getId())).thenReturn(Optional.of(ajena));

    assertThatThrownBy(
            () ->
                new IniciarReservaUseCase(reservas)
                    .execute(new ReservaStaffCommand(ajena.getId(), adminSucursal)))
        .isInstanceOf(ForbiddenException.class);
    assertThatThrownBy(
            () ->
                new CompletarReservaUseCase(reservas)
                    .execute(new ReservaStaffCommand(ajena.getId(), adminSucursal)))
        .isInstanceOf(ForbiddenException.class);
    verify(reservas, never()).save(any());

    when(reservas.save(ajena)).thenReturn(ajena);
    new IniciarReservaUseCase(reservas)
        .execute(new ReservaStaffCommand(ajena.getId(), adminTenant));
    assertThat(ajena.getEstado()).isEqualTo(ReservaEstado.EN_PROGRESO);
  }

  @Test
  void unEmpleadoNoOperaNiVeReservasDeOtraSucursal() {
    Reserva ajena = reservaEn(OTRA_SUCURSAL);
    when(reservas.findById(ajena.getId())).thenReturn(Optional.of(ajena));

    assertThatThrownBy(
            () ->
                new IniciarReservaUseCase(reservas)
                    .execute(new ReservaStaffCommand(ajena.getId(), empleado)))
        .isInstanceOf(ForbiddenException.class);
    assertThatThrownBy(
            () ->
                new CancelarReservaUseCase(reservas)
                    .execute(
                        new CancelarReservaCommand(
                            ajena.getId(), UUID.randomUUID(), true, empleado)))
        .isInstanceOf(ForbiddenException.class);
    assertThatThrownBy(
            () ->
                new ListarAgendaDelDiaUseCase(reservas)
                    .execute(
                        new AgendaDiaQuery(OTRA_SUCURSAL, AHORA, AHORA.plusSeconds(1), empleado)))
        .isInstanceOf(ForbiddenException.class);
    assertThat(
            new ListarAgendaDelDiaUseCase(reservas)
                .execute(
                    new AgendaDiaQuery(SUCURSAL_PROPIA, AHORA, AHORA.plusSeconds(1), empleado)))
        .isEmpty();
  }

  @Test
  void adminSucursalNoCancelaReservasDeOtraSucursal() {
    Reserva ajena = reservaEn(OTRA_SUCURSAL);
    when(reservas.findById(ajena.getId())).thenReturn(Optional.of(ajena));

    assertThatThrownBy(
            () ->
                new CancelarReservaUseCase(reservas)
                    .execute(
                        new CancelarReservaCommand(
                            ajena.getId(), UUID.randomUUID(), true, adminSucursal)))
        .isInstanceOf(ForbiddenException.class);
  }

  @Test
  void elReporteDeUnAdminSucursalSiempreSeFiltraPorSuSucursal() {
    var useCase = new ObtenerResumenVentasUseCase(reservas);
    when(reservas.obtenerResumenVentas(any(), any(), any()))
        .thenReturn(new ResumenVentas(Money.cop(BigDecimal.ZERO), 0, List.of()));
    Instant hasta = AHORA.plus(Duration.ofDays(1));

    useCase.execute(new ResumenVentasQuery(AHORA, hasta, null, adminSucursal));
    verify(reservas).obtenerResumenVentas(AHORA, hasta, SUCURSAL_PROPIA);

    assertThatThrownBy(
            () ->
                useCase.execute(new ResumenVentasQuery(AHORA, hasta, OTRA_SUCURSAL, adminSucursal)))
        .isInstanceOf(ForbiddenException.class);

    useCase.execute(new ResumenVentasQuery(AHORA, hasta, null, adminTenant));
    verify(reservas).obtenerResumenVentas(eq(AHORA), eq(hasta), eq(null));
  }

  @Test
  void elReporteValidaElRango() {
    var useCase = new ObtenerResumenVentasUseCase(reservas);

    assertThatThrownBy(
            () ->
                useCase.execute(
                    new ResumenVentasQuery(AHORA, AHORA.minusSeconds(1), null, adminTenant)))
        .isInstanceOf(ValidationException.class);
    assertThatThrownBy(
            () ->
                useCase.execute(
                    new ResumenVentasQuery(
                        AHORA, AHORA.plus(Duration.ofDays(367)), null, adminTenant)))
        .isInstanceOf(ValidationException.class);
  }

  private static Reserva reservaEn(UUID sucursalId) {
    return new Reserva(
        UUID.randomUUID(),
        UUID.randomUUID(),
        sucursalId,
        UUID.randomUUID(),
        UUID.randomUUID(),
        AHORA,
        20,
        Money.cop(BigDecimal.valueOf(15000)),
        ReservaEstado.PENDIENTE);
  }

  private static PrincipalAutenticado principal(Set<String> roles) {
    return new PrincipalAutenticado(
        UUID.randomUUID(), UUID.randomUUID(), SUCURSAL_PROPIA, roles, "jti");
  }
}
