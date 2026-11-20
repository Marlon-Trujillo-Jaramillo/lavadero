package com.lavadero.scheduling.interfaces.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.shared.application.exception.ValidationException;
import org.junit.jupiter.api.Test;

class ClienteCrmControllerTest {

  @Test
  void aceptaSegmentoSinImportarMayusculasYVacioEsSinFiltro() {
    assertThat(ClienteCrmController.enumOpcional(SegmentoCliente.class, " en_riesgo ", "segmento"))
        .isEqualTo(SegmentoCliente.EN_RIESGO);
    assertThat(ClienteCrmController.enumOpcional(SegmentoCliente.class, "", "segmento")).isNull();
  }

  @Test
  void unSegmentoDesconocidoEs400ConLosValoresValidos() {
    assertThatThrownBy(
            () -> ClienteCrmController.enumOpcional(SegmentoCliente.class, "vip", "segmento"))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("EN_RIESGO");
  }
}
