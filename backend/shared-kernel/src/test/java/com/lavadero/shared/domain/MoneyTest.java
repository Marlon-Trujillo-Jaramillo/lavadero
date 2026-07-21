package com.lavadero.shared.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class MoneyTest {

  @Test
  void suma_dos_montos_de_la_misma_moneda() {
    Money a = Money.cop(new BigDecimal("1000"));
    Money b = Money.cop(new BigDecimal("500.5"));

    Money resultado = a.sumar(b);

    assertThat(resultado.monto()).isEqualByComparingTo("1500.50");
  }

  @Test
  void resta_no_permite_resultado_negativo() {
    Money a = Money.cop(new BigDecimal("100"));
    Money b = Money.cop(new BigDecimal("200"));

    assertThatThrownBy(() -> a.restar(b)).isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void no_permite_operar_monedas_distintas() {
    Money cop = Money.cop(BigDecimal.TEN);
    Money usd = Money.de(BigDecimal.TEN, "USD");

    assertThatThrownBy(() -> cop.sumar(usd)).isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void multiplicar_por_factor_escala_el_monto() {
    Money precioUnitario = Money.cop(new BigDecimal("10000"));

    Money total = precioUnitario.multiplicar(new BigDecimal("3"));

    assertThat(total.monto()).isEqualByComparingTo("30000.00");
  }

  @Test
  void redondea_a_dos_decimales() {
    Money money = Money.cop(new BigDecimal("10.005"));

    assertThat(money.monto()).isEqualByComparingTo("10.01");
  }

  @Test
  void es_mayor_que_compara_correctamente() {
    Money mayor = Money.cop(new BigDecimal("100"));
    Money menor = Money.cop(new BigDecimal("50"));

    assertThat(mayor.esMayorQue(menor)).isTrue();
    assertThat(menor.esMayorQue(mayor)).isFalse();
  }
}
