package com.lavadero.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class TenantContextTest {

  @AfterEach
  void limpiar() {
    TenantContext.clear();
  }

  @Test
  void set_y_get_devuelven_el_mismo_tenant() {
    UUID tenantId = UUID.randomUUID();

    TenantContext.set(tenantId);

    assertThat(TenantContext.get()).contains(tenantId);
  }

  @Test
  void get_es_vacio_cuando_no_se_ha_seteado_nada() {
    assertThat(TenantContext.get()).isEmpty();
  }

  @Test
  void clear_elimina_el_tenant_actual() {
    TenantContext.set(UUID.randomUUID());

    TenantContext.clear();

    assertThat(TenantContext.get()).isEmpty();
  }

  @Test
  void requerido_lanza_excepcion_si_no_hay_tenant() {
    assertThatThrownBy(TenantContext::requerido).isInstanceOf(IllegalStateException.class);
  }

  @Test
  void el_contexto_esta_aislado_entre_threads() throws InterruptedException {
    UUID tenantHiloPrincipal = UUID.randomUUID();
    TenantContext.set(tenantHiloPrincipal);

    AtomicReference<UUID> visibleEnOtroHilo = new AtomicReference<>();
    CountDownLatch latch = new CountDownLatch(1);
    ExecutorService executor = Executors.newSingleThreadExecutor();
    try {
      executor.submit(
          () -> {
            // No se ha seteado nada en este hilo: debe estar vacío,
            // aun cuando el hilo principal sí tiene un tenant activo.
            visibleEnOtroHilo.set(TenantContext.get().orElse(null));
            latch.countDown();
          });
      assertThat(latch.await(5, TimeUnit.SECONDS)).isTrue();
    } finally {
      executor.shutdownNow();
    }

    assertThat(visibleEnOtroHilo.get()).isNull();
    assertThat(TenantContext.get()).contains(tenantHiloPrincipal);
  }
}
