package com.lavadero.scheduling.domain.model.crm;

/**
 * En qué momento de la relación con el lavadero está un cliente. La regla vive en una sola consulta
 * SQL (ver {@code ClienteCrmRepositoryAdapter}) para poder filtrar, contar y paginar por segmento
 * en la base de datos; los umbrales están aquí para que la regla tenga nombre y número en un solo
 * lugar. Se evalúa en el orden de la enumeración: el primero que aplica gana.
 *
 * <ol>
 *   <li>{@link #SIN_VISITAS}: tiene cuenta (o reservas pendientes/canceladas) pero ningún servicio
 *       completado.
 *   <li>{@link #EN_RIESGO}: ya debería haber vuelto y no tiene una próxima reserva. "Debería"
 *       depende de su propio ritmo: el doble de su intervalo promedio entre visitas, nunca menos de
 *       {@link #DIAS_MINIMOS_RIESGO} días. Con una sola visita no hay ritmo: {@link
 *       #DIAS_RIESGO_UNA_VISITA} días.
 *   <li>{@link #NUEVO}: su primera visita fue hace menos de {@link #DIAS_VENTANA_NUEVO} días.
 *   <li>{@link #FRECUENTE}: al menos {@link #VISITAS_FRECUENTE} visitas y vuelve, en promedio, cada
 *       {@link #DIAS_INTERVALO_FRECUENTE} días o menos.
 *   <li>{@link #OCASIONAL}: el resto.
 * </ol>
 */
public enum SegmentoCliente {
  SIN_VISITAS,
  EN_RIESGO,
  NUEVO,
  FRECUENTE,
  OCASIONAL;

  public static final int DIAS_MINIMOS_RIESGO = 30;
  public static final int DIAS_RIESGO_UNA_VISITA = 60;
  public static final int DIAS_VENTANA_NUEVO = 30;
  public static final int VISITAS_FRECUENTE = 4;
  public static final int DIAS_INTERVALO_FRECUENTE = 30;
}
