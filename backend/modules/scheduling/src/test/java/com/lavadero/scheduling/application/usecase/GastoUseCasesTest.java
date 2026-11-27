package com.lavadero.scheduling.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.lavadero.scheduling.application.command.ListarGastosQuery;
import com.lavadero.scheduling.application.command.RegistrarGastoCommand;
import com.lavadero.scheduling.application.command.ResumenFinancieroQuery;
import com.lavadero.scheduling.application.dto.GastoDto;
import com.lavadero.scheduling.application.dto.ResumenFinancieroDto;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import com.lavadero.scheduling.domain.model.gasto.Gasto;
import com.lavadero.scheduling.domain.repository.GastoRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.TenantContext;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class GastoUseCasesTest {

  private static final Instant AHORA = Instant.parse("2026-11-20T12:00:00Z");
  private final Clock reloj = Clock.fixed(AHORA, ZoneOffset.UTC);
  private final GastoRepository gastos = mock(GastoRepository.class);
  private final ReservaRepository reservas = mock(ReservaRepository.class);
  private final java.util.UUID tenant = java.util.UUID.randomUUID();

  @BeforeEach
  void setUp() {
    TenantContext.set(tenant);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  @Test
  void registrarGuardaElGastoConElTenantDelContexto() {
    when(gastos.save(any())).thenAnswer(i -> i.getArgument(0));

    GastoDto dto =
        new RegistrarGastoUseCase(gastos, reloj)
            .execute(
                new RegistrarGastoCommand(
                    null,
                    LocalDate.of(2026, 11, 20),
                    CategoriaGasto.ARRIENDO,
                    "Arriendo del local",
                    new BigDecimal("1200000"),
                    null,
                    AlcanceSucursal.todoElTenant()));

    assertThat(dto.categoria()).isEqualTo(CategoriaGasto.ARRIENDO);
    assertThat(dto.monto()).isEqualByComparingTo("1200000");
    assertThat(dto.moneda()).isEqualTo("COP");
  }

  @Test
  void utilidadEsIngresosMenosGastos() {
    when(reservas.obtenerResumenVentas(any(), any(), any()))
        .thenReturn(new ResumenVentas(Money.cop(new BigDecimal("200000")), 5, List.of()));
    when(gastos.sumar(any(), any(), any())).thenReturn(Money.cop(new BigDecimal("50000")));

    ResumenFinancieroDto dto = resumen().execute(query(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30)));

    assertThat(dto.ingresos()).isEqualByComparingTo("200000");
    assertThat(dto.gastos()).isEqualByComparingTo("50000");
    assertThat(dto.utilidad()).isEqualByComparingTo("150000");
  }

  @Test
  void laUtilidadPuedeSerNegativa() {
    when(reservas.obtenerResumenVentas(any(), any(), any()))
        .thenReturn(new ResumenVentas(Money.cop(new BigDecimal("100000")), 2, List.of()));
    when(gastos.sumar(any(), any(), any())).thenReturn(Money.cop(new BigDecimal("150000")));

    ResumenFinancieroDto dto = resumen().execute(query(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30)));

    assertThat(dto.utilidad()).isEqualByComparingTo("-50000");
  }

  @Test
  void rechazaRangoInvertido() {
    assertThatThrownBy(
            () -> resumen().execute(query(LocalDate.of(2026, 11, 30), LocalDate.of(2026, 11, 1))))
        .isInstanceOf(ValidationException.class);
  }

  @Test
  void listarRechazaRangoInvertido() {
    assertThatThrownBy(
            () ->
                new ListarGastosUseCase(gastos)
                    .execute(
                        new ListarGastosQuery(
                            LocalDate.of(2026, 11, 30),
                            LocalDate.of(2026, 11, 1),
                            null,
                            AlcanceSucursal.todoElTenant())))
        .isInstanceOf(ValidationException.class);
  }

  private ObtenerResumenFinancieroUseCase resumen() {
    return new ObtenerResumenFinancieroUseCase(reservas, gastos);
  }

  private ResumenFinancieroQuery query(LocalDate desde, LocalDate hasta) {
    return new ResumenFinancieroQuery(desde, hasta, null, AlcanceSucursal.todoElTenant());
  }
}
