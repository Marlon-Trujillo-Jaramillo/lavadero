package com.lavadero.scheduling.domain.model.crm;

/** Orden de la lista de clientes del CRM. */
public enum OrdenClientes {
  /** Los que vinieron hace menos primero; los que nunca vinieron al final. */
  ULTIMA_VISITA,
  GASTO,
  VISITAS,
  NOMBRE
}
