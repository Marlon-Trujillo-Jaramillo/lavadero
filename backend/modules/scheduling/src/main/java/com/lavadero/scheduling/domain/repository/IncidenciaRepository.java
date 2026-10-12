package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.Incidencia;
import java.util.List;
import java.util.UUID;

public interface IncidenciaRepository {

  List<Incidencia> findByReportadoPorUsuarioId(UUID usuarioId);

  Incidencia save(Incidencia incidencia);
}
