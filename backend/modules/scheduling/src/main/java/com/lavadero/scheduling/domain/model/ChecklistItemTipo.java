package com.lavadero.scheduling.domain.model;

/**
 * Tareas estándar de un lavado. Lista fija (no configurable por tenant) en esta fase — ver
 * docs/specs/006-checklist-incidencias.md para el porqué de no modelar plantillas por tenant
 * todavía (YAGNI hasta que un tenant real lo pida).
 */
public enum ChecklistItemTipo {
  EXTERIOR_LAVADO("Exterior lavado"),
  INTERIOR_ASPIRADO("Interior aspirado"),
  LLANTAS("Llantas"),
  SECADO("Secado"),
  AROMATIZANTE("Aromatizante");

  private final String label;

  ChecklistItemTipo(String label) {
    this.label = label;
  }

  public String getLabel() {
    return label;
  }
}
