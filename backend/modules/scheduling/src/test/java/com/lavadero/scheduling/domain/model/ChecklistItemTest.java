package com.lavadero.scheduling.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class ChecklistItemTest {

  @Test
  void nuevo_item_empieza_no_completado() {
    ChecklistItem item =
        ChecklistItem.nuevo(UUID.randomUUID(), UUID.randomUUID(), ChecklistItemTipo.SECADO);
    assertThat(item.isCompletado()).isFalse();
    assertThat(item.getCompletadoEn()).isNull();
  }

  @Test
  void marcar_completado_fija_completadoEn() {
    ChecklistItem item =
        ChecklistItem.nuevo(UUID.randomUUID(), UUID.randomUUID(), ChecklistItemTipo.SECADO);
    item.marcar(true);
    assertThat(item.isCompletado()).isTrue();
    assertThat(item.getCompletadoEn()).isNotNull();
  }

  @Test
  void desmarcar_limpia_completadoEn() {
    ChecklistItem item =
        ChecklistItem.nuevo(UUID.randomUUID(), UUID.randomUUID(), ChecklistItemTipo.SECADO);
    item.marcar(true);
    item.marcar(false);
    assertThat(item.isCompletado()).isFalse();
    assertThat(item.getCompletadoEn()).isNull();
  }
}
