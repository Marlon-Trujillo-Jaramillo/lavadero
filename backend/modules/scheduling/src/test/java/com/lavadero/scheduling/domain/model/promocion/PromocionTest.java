package com.lavadero.scheduling.domain.model.promocion;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PromocionTest {

  private static final UUID TENANT = UUID.randomUUID();
  private static final Money LAVADO = Money.cop(new BigDecimal("45000"));
  // Martes 17 de noviembre de 2026, hora de Bogotá.
  private static final LocalDate HOY = LocalDate.of(2026, 11, 17);

  private static Instant bogota(int dia, int hora, int minuto) {
    return LocalDateTime.of(2026, 11, dia, hora, minuto).atZone(Promocion.ZONA_HORARIA).toInstant();
  }

  @Test
  void elPorcentajeSeRedondeaAPesosEnterosYElMontoFijoNuncaDejaPrecioNegativo() {
    assertThat(Descuento.porcentaje(15).calcular(Money.cop(new BigDecimal("33333"))).monto())
        .isEqualByComparingTo("5000"); // 4999.95 → 5000
    assertThat(Descuento.montoFijo(Money.cop(new BigDecimal("60000"))).calcular(LAVADO).monto())
        .isEqualByComparingTo("45000");
  }

  @Test
  void rechazaPorcentajesFueraDeRangoOConDecimales() {
    assertThatThrownBy(() -> Descuento.porcentaje(0)).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> Descuento.porcentaje(91)).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new Descuento(TipoDescuento.PORCENTAJE, new BigDecimal("12.5"), null))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void elCodigoSeNormalizaYValidaSuFormato() {
    assertThat(CodigoCupon.de(" verano 24 ").valor()).isEqualTo("VERANO24");
    assertThat(CodigoCupon.de("black-friday").valor()).isEqualTo("BLACK-FRIDAY");
    assertThatThrownBy(() -> CodigoCupon.de("ab")).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> CodigoCupon.de("50%OFF")).isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void laFranjaIncluyeElInicioExcluyeElFinYGuardaLosDiasComoMascara() {
    FranjaHoraria manana =
        new FranjaHoraria(
            Set.of(DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY),
            LocalTime.of(8, 0),
            LocalTime.of(11, 0));

    assertThat(manana.contiene(LocalDateTime.of(2026, 11, 17, 8, 0))).isTrue();
    assertThat(manana.contiene(LocalDateTime.of(2026, 11, 17, 11, 0))).isFalse();
    assertThat(manana.contiene(LocalDateTime.of(2026, 11, 19, 9, 0))).isFalse(); // jueves
    assertThat(manana.mascara()).isEqualTo(2 | 4);
    assertThat(FranjaHoraria.diasDeMascara(manana.mascara())).isEqualTo(manana.dias());
  }

  @Test
  void laFranjaSeLeeEnHoraDeBogotaNoEnUtc() {
    Promocion horaValle = horario(8, 11);

    // 9:00 en Bogotá son las 14:00 UTC.
    assertThat(horaValle.aplicaA(Instant.parse("2026-11-17T14:00:00Z"))).isTrue();
    assertThat(horaValle.aplicaA(Instant.parse("2026-11-17T09:00:00Z"))).isFalse();
  }

  @Test
  void explicaPorQueNoAplica() {
    Promocion cupon =
        Promocion.cupon(
            TENANT,
            "Bienvenida",
            CodigoCupon.de("HOLA"),
            Descuento.porcentaje(10),
            HOY,
            HOY.plusDays(5),
            null,
            Instant.now());

    assertThat(cupon.motivoNoAplica(bogota(16, 10, 0))).get().asString().contains("empieza");
    assertThat(cupon.motivoNoAplica(bogota(23, 10, 0))).get().asString().contains("venció");
    cupon.desactivar();
    assertThat(cupon.motivoNoAplica(bogota(18, 10, 0))).get().asString().contains("activa");
  }

  @Test
  void unCuponAgotadoNoAplica() {
    Promocion agotado =
        new Promocion(
            UUID.randomUUID(),
            TENANT,
            "Primeros 2",
            TipoPromocion.CUPON,
            CodigoCupon.de("PRIMEROS"),
            Descuento.porcentaje(20),
            null,
            HOY,
            HOY.plusDays(30),
            2,
            2,
            true,
            Instant.now());

    assertThat(agotado.motivoNoAplica(bogota(18, 10, 0))).get().asString().contains("agotó");
  }

  @Test
  void noSeAcumulanGanaLaQueMasDescuenta() {
    Promocion horaValle = horario(8, 11); // 20 %
    Promocion cuponChico =
        Promocion.cupon(
            TENANT,
            "Cupón 5 mil",
            CodigoCupon.de("CINCO"),
            Descuento.montoFijo(Money.cop(new BigDecimal("5000"))),
            HOY,
            HOY.plusDays(30),
            null,
            Instant.now());

    PrecioCotizado enHoraValle =
        CotizadorPrecios.cotizar(LAVADO, bogota(17, 9, 0), List.of(horaValle, cuponChico));
    PrecioCotizado fueraDeHora =
        CotizadorPrecios.cotizar(LAVADO, bogota(17, 15, 0), List.of(horaValle, cuponChico));
    PrecioCotizado sinNada = CotizadorPrecios.cotizar(LAVADO, bogota(17, 15, 0), List.of());

    assertThat(enHoraValle.promocion()).isSameAs(horaValle);
    assertThat(enHoraValle.precioFinal().monto()).isEqualByComparingTo("36000");
    assertThat(fueraDeHora.promocion()).isSameAs(cuponChico);
    assertThat(fueraDeHora.precioFinal().monto()).isEqualByComparingTo("40000");
    assertThat(sinNada.getPromocion()).isEmpty();
    assertThat(sinNada.precioFinal()).isEqualTo(LAVADO);
  }

  private static Promocion horario(int desde, int hasta) {
    return Promocion.horario(
        TENANT,
        "Mañanas de martes",
        new FranjaHoraria(
            Set.of(DayOfWeek.TUESDAY), LocalTime.of(desde, 0), LocalTime.of(hasta, 0)),
        Descuento.porcentaje(20),
        HOY.minusDays(1),
        HOY.plusDays(30),
        Instant.now());
  }
}
