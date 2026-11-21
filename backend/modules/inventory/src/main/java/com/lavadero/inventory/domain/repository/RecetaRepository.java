package com.lavadero.inventory.domain.repository;

import com.lavadero.inventory.domain.model.LineaReceta;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface RecetaRepository {

  List<LineaReceta> deServicio(UUID servicioId);

  /** Todas las recetas del lavadero, por servicio. */
  Map<UUID, List<LineaReceta>> todas();

  /** Reemplaza la receta completa del servicio (una lista vacía la borra). */
  void reemplazar(UUID tenantId, UUID servicioId, List<LineaReceta> lineas);
}
