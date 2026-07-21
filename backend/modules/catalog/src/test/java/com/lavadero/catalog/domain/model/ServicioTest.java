package com.lavadero.catalog.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ServicioTest {

  private static final UUID TENANT_ID = UUID.randomUUID();
  private static final Money PRECIO = Money.cop(new BigDecimal("15000"));

  @Test
  void nuevo_crea_un_servicio_activo_por_defecto() {
    Servicio servicio = Servicio.nuevo(TENANT_ID, "Lavado básico", "Exterior", 20, PRECIO);

    assertThat(servicio.isActivo()).isTrue();
    assertThat(servicio.getNombre()).isEqualTo("Lavado básico");
    assertThat(servicio.getDuracionEstimadaMinutos()).isEqualTo(20);
  }

  @Test
  void no_permite_nombre_vacio() {
    assertThatThrownBy(() -> Servicio.nuevo(TENANT_ID, "  ", null, 20, PRECIO))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void no_permite_duracion_menor_a_un_minuto() {
    assertThatThrownBy(() -> Servicio.nuevo(TENANT_ID, "Lavado básico", null, 0, PRECIO))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void activar_y_desactivar_cambian_el_estado() {
    Servicio servicio = Servicio.nuevo(TENANT_ID, "Lavado básico", null, 20, PRECIO);

    servicio.desactivar();
    assertThat(servicio.isActivo()).isFalse();

    servicio.activar();
    assertThat(servicio.isActivo()).isTrue();
  }

  @Test
  void actualizar_precio_reemplaza_el_valor() {
    Servicio servicio = Servicio.nuevo(TENANT_ID, "Lavado básico", null, 20, PRECIO);

    servicio.actualizarPrecio(Money.cop(new BigDecimal("20000")));

    assertThat(servicio.getPrecio().monto()).isEqualByComparingTo("20000.00");
  }
}
